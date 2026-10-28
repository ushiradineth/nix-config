#!/usr/bin/env bash
set -euo pipefail

task_dir="$(mktemp -d)"
trap 'rm -rf "$task_dir"' EXIT
helper="$1"
log="$task_dir/decisions.tsv"

if bash "$helper" "$log"; then
  echo "missing columns must fail" >&2
  exit 1
fi

bash "$helper" "$log" frame 'picked the owner' 'one state model' 'src/cache.ts' verified
bash "$helper" "$log" build $'kept\tthe\nshape\r' '=unsafe' '+evidence' '@result'

[ "$(wc -l <"$log" | tr -d ' ')" -eq 3 ]
[ "$(head -n 1 "$log")" = $'ts\tphase\tdecision\twhy\tevidence\tresult' ]
cut -f2- "$log" >"$task_dir/actual"
cat >"$task_dir/expected" <<'EOF'
phase	decision	why	evidence	result
frame	picked the owner	one state model	src/cache.ts	verified
build	kept the shape 	'=unsafe	'+evidence	'@result
EOF
diff -u "$task_dir/expected" "$task_dir/actual"
echo "decision log append, cell escaping and argument checks passed"
