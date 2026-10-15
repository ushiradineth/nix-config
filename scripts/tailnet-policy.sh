#!/usr/bin/env bash
# Explicit operator approval is required before invoking apply or rollback.
set +x
set +a
set -euo pipefail
umask 077

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}
[[ ${TAILSCALE_TAILNET:-} =~ ^[A-Za-z0-9][A-Za-z0-9.@_-]*$ ]] || fail 'Explicit valid TAILSCALE_TAILNET required'
[[ ${TAILSCALE_API_TOKEN:-} =~ ^[A-Za-z0-9._-]+$ ]] || fail 'Explicit valid TAILSCALE_API_TOKEN required'
# Keep credentials only in shell memory and curl stdin, never child environments.
export -n auth
auth="header = \"Authorization: Bearer ${TAILSCALE_API_TOKEN}\""
unset TAILSCALE_API_TOKEN
tailnet=$TAILSCALE_TAILNET
url="https://api.tailscale.com/api/v2/tailnet/$tailnet/acl"
work=$(mktemp -d)
write_pending=0
trap 'rm -rf -- "$work"' EXIT
trap 'fail "Interrupted; any write has unknown-outcome. Use approved export readback; never retry blindly."' HUP INT TERM

digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 -- "$1" | cut -d ' ' -f 1
  fi
}
normalize_policy() {
  # Ignore only HuJSON presentation, not values, number precision, key/array order or duplicates.
  jq -Rrs '
    def quoted: "\"(?:\\\\.|[^\"\\\\])*\"";
    def tokens($pattern):
      . as $raw | [match($pattern; "g")] as $matches |
      if (($matches | map(.length) | add) // 0) != ($raw | length)
      then error("unrecognized policy bytes") else $matches end;
    def retain:
      map(select(any(.captures[]; (.name == "quoted" or .name == "other") and .string != null)) | .string) | join("");
    tokens("(?<quoted>" + quoted + ")|(?<comment>//[^\\r\\n]*|/\\*(?:[^*]|\\*(?!/))*\\*/)|(?<space>[ \\t\\r\\n]+)|(?<other>.)") | retain |
    tokens("(?<quoted>" + quoted + ")|(?<trailing>,(?=[}\\]]))|(?<other>.)") | retain |
    . as $canonical | fromjson |
    if type == "object" then $canonical else error("policy must be an object") end
  ' "$1"
}
policy_equal() {
  local approved returned
  approved=$(normalize_policy "$1" 2>/dev/null) || fail 'Invalid reviewed HuJSON policy'
  if ! returned=$(normalize_policy "$2" 2>/dev/null); then
    [[ $write_pending == 0 ]] || fail 'unknown-outcome: malformed policy readback; approved export required, no write retry'
    fail 'Malformed live policy; stopped without write'
  fi
  [[ $approved == "$returned" ]]
}
regular() { [[ -f $1 && ! -L $1 ]] || fail 'Missing or symlink artifact'; }
etag_value() {
  regular "$1"
  etag=$(<"$1")
  [[ $etag =~ ^\"[A-Za-z0-9._:-]+\"$ ]] || fail 'Missing or invalid quoted ETag'
}
request() {
  local method=$1 endpoint=$2 body=${3:-} match=${4:-} status
  local args=(--disable --config - --silent --show-error --connect-timeout 10 --max-time 30
    --proto '=https' --request "$method" --dump-header "$work/headers" --output "$work/body" --write-out '%{http_code}')
  if [[ -n $body ]]; then args+=(--header 'Content-Type: application/hujson' --data-binary "@$body"); fi
  if [[ -n $match ]]; then args+=(--header "If-Match: $match"); fi
  if ! status=$(printf '%s\n' "$auth" | curl "${args[@]}" "$endpoint" 2>"$work/curl-error"); then
    if [[ $method == POST && $endpoint == "$url" ]]; then
      fail 'unknown-outcome: write transport failure; approved export readback required, no write retry'
    fi
    [[ $write_pending == 0 ]] || fail 'unknown-outcome: readback transport failure; approved export required, no write retry'
    fail 'API transport failure'
  fi
  [[ $write_pending == 0 || $status == 200 ]] || fail 'unknown-outcome: readback HTTP failure; approved export required, no write retry'
  [[ $status == 200 ]] || fail "API HTTP $status; stopped without retry"
  if [[ $method == POST && $endpoint == "$url" ]]; then write_pending=1; fi
}
fetch() {
  request GET "$url"
  # Reject ambiguous duplicate headers and weak/missing ETags.
  local line found=0
  etag=''
  while IFS= read -r line; do
    line=${line%$'\r'}
    if [[ $line =~ ^[Ee][Tt][Aa][Gg]: ]]; then
      found=$((found + 1))
      etag=${line#*:}
      etag=${etag# }
    fi
  done <"$work/headers"
  if [[ $found != 1 || ! $etag =~ ^\"[A-Za-z0-9._:-]+\"$ || ! -s $work/body ]]; then
    [[ $write_pending == 0 ]] || fail 'unknown-outcome: invalid readback; approved export required, no write retry'
    fail 'Empty policy or missing/invalid quoted ETag'
  fi
}
publish_file() {
  # Hard-link creation is atomic and refuses existing files, including symlinks.
  # Stage beside the destination so atomic creation also works across filesystems.
  local staged
  staged=$(mktemp "$(dirname -- "$2")/.tailnet-artifact.XXXXXX")
  cp -- "$1" "$staged"
  chmod 600 "$staged"
  if ! ln -- "$staged" "$2" 2>/dev/null; then
    rm -f -- "$staged"
    fail 'Artifact already exists or destination unavailable'
  fi
  rm -f -- "$staged"
}
private_parent() {
  local parent mode
  parent=$(dirname -- "$1")
  [[ -d $parent && ! -L $parent ]] || fail 'Artifact parent must be an existing private directory'
  mode=$(stat -c '%a' -- "$parent" 2>/dev/null) || mode=$(stat -f '%Lp' "$parent")
  [[ $mode == 700 ]] || fail 'Artifact parent directory must have mode 0700'
}
check_baseline() {
  regular "$prefix.hujson"
  regular "$prefix.metadata.json"
  etag_value "$prefix.etag"
  baseline_digest=$(digest "$prefix.hujson")
  jq -e --arg t "$tailnet" --arg d "$baseline_digest" --arg e "$etag" \
    '.tailnet == $t and .baseline_digest == $d and .etag == $e' "$prefix.metadata.json" >/dev/null 2>&1 || fail 'Export metadata identity/digest/ETag mismatch'
}
validate_body() {
  request POST "$url/validate" "$1"
  # Unknown nonempty fields are diagnostics too; do not assume HTTP 200 means pass.
  jq -se 'length == 0 or (length == 1 and (.[0] | type == "object" and all(.[]; . == null or . == "" or . == [])))' \
    "$work/body" >/dev/null 2>&1 || fail 'Policy validation diagnostics or malformed response; publication blocked'
}
absolute() {
  local parent name
  parent=$(dirname -- "$1")
  name=$(basename -- "$1")
  printf '%s/%s\n' "$(cd -- "$parent" && pwd -P)" "$name"
}
load_review() {
  regular "$review"
  jq -e --arg t "$tailnet" '.tailnet == $t and
    ([.baseline_prefix, .baseline_snapshot, .candidate_snapshot, .baseline_digest, .candidate_digest, .etag] |
    all(.[]; type == "string" and length > 0 and (test("[\\r\\n]") | not)))' \
    "$review" >/dev/null 2>&1 || fail 'Invalid review or tailnet identity mismatch'
  prefix=$(jq -r '.baseline_prefix' "$review")
  original=$(jq -r '.baseline_snapshot' "$review")
  snapshot=$(jq -r '.candidate_snapshot' "$review")
  expected=$(jq -r '.candidate_digest' "$review")
  check_baseline
  jq -e --arg b "$baseline_digest" --arg e "$etag" '.baseline_digest == $b and .etag == $e' \
    "$review" >/dev/null || fail 'Review baseline/ETag mismatch'
  regular "$original"
  regular "$snapshot"
  [[ $(digest "$original") == "$baseline_digest" && $(digest "$snapshot") == "$expected" ]] || fail 'Reviewed snapshot mutation'
  # Copy into this invocation's private directory, then validate/check and upload that copy.
  cp -- "$snapshot" "$work/candidate"
  cp -- "$original" "$work/original"
  [[ $(digest "$work/candidate") == "$expected" && $(digest "$work/original") == "$baseline_digest" ]] || fail 'Snapshot changed during copy'
  normalize_policy "$work/candidate" >/dev/null 2>&1 || fail 'Invalid reviewed HuJSON candidate'
  normalize_policy "$work/original" >/dev/null 2>&1 || fail 'Invalid reviewed HuJSON baseline'
}
command=${1:-}
shift || true
for argument in "$@"; do
  [[ $argument != *$'\n'* && $argument != *$'\r'* ]] || fail 'Newlines in arguments are not allowed'
done
case "$command" in
export)
  [[ $# == 1 ]] || fail 'Usage: export PREFIX'
  prefix=$1
  private_parent "$prefix"
  for suffix in hujson etag metadata.json; do [[ ! -e $prefix.$suffix && ! -L $prefix.$suffix ]] || fail 'Export artifact already exists'; done
  fetch
  printf '%s\n' "$etag" >"$work/etag"
  jq -n --arg t "$tailnet" --arg d "$(digest "$work/body")" --arg e "$etag" \
    '{tailnet:$t, baseline_digest:$d, etag:$e}' >"$work/metadata"
  publish_file "$work/body" "$prefix.hujson"
  publish_file "$work/etag" "$prefix.etag"
  publish_file "$work/metadata" "$prefix.metadata.json"
  ;;
validate)
  [[ $# == 5 && $2 == --baseline-prefix && $4 == --review-file ]] || fail 'Usage: validate CANDIDATE --baseline-prefix PREFIX --review-file FILE'
  candidate=$1
  prefix=$(absolute "$3")
  review=$(absolute "$5")
  private_parent "$review"
  regular "$candidate"
  [[ ! -e $review && ! -L $review ]] || fail 'Review artifact already exists'
  check_baseline
  # Retain only successful reviews. Private copies provide the immutable review bytes.
  cp -- "$candidate" "$work/candidate"
  cp -- "$prefix.hujson" "$work/original"
  chmod 600 "$work/candidate" "$work/original"
  [[ $(digest "$work/original") == "$baseline_digest" ]] || fail 'Baseline changed during copy'
  expected=$(digest "$work/candidate")
  normalize_policy "$work/candidate" >/dev/null 2>&1 || fail 'Invalid HuJSON candidate'
  validate_body "$work/candidate"
  snapshots=$(mktemp -d "${review}.snapshots.XXXXXX")
  cp -- "$work/candidate" "$snapshots/candidate.hujson"
  cp -- "$work/original" "$snapshots/baseline.hujson"
  chmod 600 "$snapshots/candidate.hujson" "$snapshots/baseline.hujson"
  jq -n --arg t "$tailnet" --arg b "$baseline_digest" --arg c "$expected" --arg e "$etag" \
    --arg p "$prefix" --arg s "$snapshots/candidate.hujson" --arg o "$snapshots/baseline.hujson" \
    '{tailnet:$t, baseline_digest:$b, candidate_digest:$c, etag:$e, baseline_prefix:$p,
        candidate_snapshot:$s, baseline_snapshot:$o}' >"$work/review"
  publish_file "$work/review" "$review"
  ;;
diff)
  [[ $# == 1 ]] || fail 'Usage: diff CANDIDATE'
  regular "$1"
  cp -- "$1" "$work/candidate"
  fetch
  result=0
  diff -u -- "$work/body" "$work/candidate" || result=$?
  [[ $result -le 1 ]] || fail 'Diff failed'
  ;;
apply)
  [[ $# == 5 && $2 == --if-match-file && $4 == --review-file ]] || fail 'Usage: apply CANDIDATE --if-match-file FILE --review-file FILE'
  candidate=$1
  match_file=$3
  review=$5
  load_review
  regular "$candidate"
  [[ $(digest "$candidate") == "$expected" ]] || fail 'Candidate mutation'
  reviewed_etag=$etag
  etag_value "$match_file"
  [[ $etag == "$reviewed_etag" ]] || fail 'If-Match/review ETag mismatch'
  validate_body "$work/candidate"
  request POST "$url" "$work/candidate" "$reviewed_etag"
  fetch
  policy_equal "$work/candidate" "$work/body" || fail 'unknown-outcome: readback differs; stop, no automatic rollback or retry'
  printf '%s\n' 'Applied and readback verified'
  ;;
verify)
  [[ $# == 2 && $1 == --review-file ]] || fail 'Usage: verify --review-file FILE'
  review=$2
  load_review
  fetch
  policy_equal "$work/candidate" "$work/body" || fail 'Live policy differs from reviewed candidate'
  printf '%s\n' 'Live policy matches reviewed candidate'
  ;;
rollback)
  [[ $# == 2 && $1 == --review-file ]] || fail 'Usage: rollback --review-file FILE'
  review=$2
  load_review
  # Validate saved original before obtaining the fresh conditional-write ETag.
  validate_body "$work/original"
  fetch
  policy_equal "$work/candidate" "$work/body" || fail 'Rollback refused: current policy is not the reviewed candidate'
  fresh_etag=$etag
  request POST "$url" "$work/original" "$fresh_etag"
  fetch
  policy_equal "$work/original" "$work/body" || fail 'unknown-outcome: rollback readback differs; stop without retry'
  printf '%s\n' 'Rolled back and readback verified'
  ;;
*) fail 'Usage: export | validate | diff | apply | verify | rollback (explicit arguments required)' ;;
esac
