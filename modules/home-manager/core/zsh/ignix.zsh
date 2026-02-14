gitignore_nix_dev_flake_on_current_git_repo() {
    local git_dir exclude_file
    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || {
        echo "Not inside a git repository" >&2
        return 1
    }
    exclude_file="$git_dir/info/exclude"
    mkdir -p "$(dirname "$exclude_file")"
    touch "$exclude_file"
    for pattern in .envrc .direnv/ flake.nix flake.lock; do
        grep -Fxq "$pattern" "$exclude_file" || printf '%s\n' "$pattern" >> "$exclude_file"
    done
    echo "Updated $exclude_file"
}

alias ignix='gitignore_nix_dev_flake_on_current_git_repo'

gitunignore_nix_dev_flake_on_current_git_repo() {
    local git_dir exclude_file tmp_file
    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || {
        echo "Not inside a git repository" >&2
        return 1
    }
    exclude_file="$git_dir/info/exclude"
    if [[ ! -f "$exclude_file" ]]; then
        echo "No $exclude_file found"
        return 0
    fi

    tmp_file="$(mktemp)"
    cp "$exclude_file" "$tmp_file"
    for pattern in .envrc .direnv/ flake.nix flake.lock; do
        grep -Fxv "$pattern" "$tmp_file" > "${tmp_file}.next" || true
        mv "${tmp_file}.next" "$tmp_file"
    done
    mv "$tmp_file" "$exclude_file"
    echo "Updated $exclude_file"
}

alias unignix='gitunignore_nix_dev_flake_on_current_git_repo'
