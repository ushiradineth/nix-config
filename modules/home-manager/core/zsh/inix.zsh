_external_dev_flake_repo_context() {
    local repo_root
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo "Not inside a git repository" >&2
        return 1
    }
    printf '%s\n' "$repo_root"
}

_external_dev_flake_update_exclude() {
    local repo_root git_dir exclude_file
    repo_root="$1"
    git_dir="$(git -C "$repo_root" rev-parse --git-dir 2>/dev/null)" || {
        echo "Failed to resolve git dir" >&2
        return 1
    }
    exclude_file="$git_dir/info/exclude"
    mkdir -p "$(dirname "$exclude_file")"
    touch "$exclude_file"
    for pattern in .envrc .direnv/; do
        grep -Fxq "$pattern" "$exclude_file" || printf '%s\n' "$pattern" >> "$exclude_file"
    done
    printf '%s\n' "$exclude_file"
}

init_external_dev_flake_on_current_git_repo() {
    local repo_root repo_name external_base external_dir template_dir envrc_path
    local templates selection selected_template exclude_file

    repo_root="$(_external_dev_flake_repo_context)" || return 1
    repo_name="${repo_root:t}"
    external_base="/Users/shu/Code/flakes"
    external_dir="$external_base/$repo_name"
    template_dir="$HOME/nix-config/flakes"

    mkdir -p "$external_dir"

    templates=("$template_dir"/*.nix(N))
    if (( ${#templates[@]} == 0 )); then
        echo "No templates found in $template_dir" >&2
        return 1
    fi

    echo "Choose a flake template for $repo_name:"
    local index=1
    for selected_template in "${templates[@]}"; do
        printf '  %d) %s\n' "$index" "${selected_template:t}"
        ((index++))
    done

    while true; do
        printf 'Template number: '
        read -r selection
        [[ "$selection" == <-> ]] || {
            echo "Enter a valid number" >&2
            continue
        }
        if (( selection < 1 || selection > ${#templates[@]} )); then
            echo "Number must be between 1 and ${#templates[@]}" >&2
            continue
        fi
        break
    done

    selected_template="${templates[$selection]}"
    cp "$selected_template" "$external_dir/flake.nix"

    if ! command -v nix >/dev/null 2>&1; then
        echo "nix command not found" >&2
        return 1
    fi

    (
        cd "$external_dir" || exit 1
        nix flake lock
    ) || {
        echo "Failed to generate flake.lock in $external_dir" >&2
        return 1
    }

    envrc_path="$repo_root/.envrc"
    printf 'use flake %s\n' "$external_dir" > "$envrc_path"

    if command -v direnv >/dev/null 2>&1; then
        (
            cd "$repo_root" || exit 1
            direnv allow
        ) || echo "direnv allow failed. Run it manually in $repo_root" >&2
    else
        echo "direnv command not found. Run 'direnv allow' in $repo_root" >&2
    fi

    exclude_file="$(_external_dev_flake_update_exclude "$repo_root")" || return 1

    echo "External flake initialized: $external_dir"
    echo "Template copied: ${selected_template:t}"
    echo "Repo envrc written: $envrc_path"
    echo "Updated $exclude_file"
}

alias inix='init_external_dev_flake_on_current_git_repo'

edit_external_dev_flake_on_current_git_repo() {
    local repo_root repo_name external_base external_dir flake_path
    repo_root="$(_external_dev_flake_repo_context)" || return 1
    repo_name="${repo_root:t}"
    external_base="/Users/shu/Code/flakes"
    external_dir="$external_base/$repo_name"
    flake_path="$external_dir/flake.nix"

    mkdir -p "$external_dir"
    if [[ ! -f "$flake_path" ]]; then
        touch "$flake_path"
    fi

    if ! command -v nvim >/dev/null 2>&1; then
        echo "nvim command not found" >&2
        return 1
    fi

    nvim "$flake_path"
}

alias einix='edit_external_dev_flake_on_current_git_repo'

gitunignore_external_dev_flake_on_current_git_repo() {
    local repo_root git_dir exclude_file tmp_file
    repo_root="$(_external_dev_flake_repo_context)" || return 1
    git_dir="$(git -C "$repo_root" rev-parse --git-dir 2>/dev/null)" || {
        echo "Failed to resolve git dir" >&2
        return 1
    }
    exclude_file="$git_dir/info/exclude"

    if [[ ! -f "$exclude_file" ]]; then
        echo "No $exclude_file found"
        return 0
    fi

    tmp_file="$(mktemp)"
    cp "$exclude_file" "$tmp_file"
    for pattern in .envrc .direnv/; do
        grep -Fxv "$pattern" "$tmp_file" > "${tmp_file}.next" || true
        mv "${tmp_file}.next" "$tmp_file"
    done
    mv "$tmp_file" "$exclude_file"
    echo "Updated $exclude_file"
}

alias uinix='gitunignore_external_dev_flake_on_current_git_repo'
