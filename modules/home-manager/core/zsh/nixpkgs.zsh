nix_run_nixpkgs() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: nix_run_nixpkgs <pkg> [pkg ...] [-- <args ...>]" >&2
        return 1
    fi

    local -a installables run_args
    local pkg

    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--" ]]; then
            shift
            run_args=("$@")
            break
        fi

        pkg="$1"
        if [[ "$pkg" == *"#"* ]]; then
            installables+=("$pkg")
        else
            installables+=("nixpkgs#$pkg")
        fi
        shift
    done

    if [[ ${#run_args[@]} -gt 0 ]]; then
        nix run "${installables[@]}" -- "${run_args[@]}"
    else
        nix run "${installables[@]}"
    fi
}

alias nr='nix_run_nixpkgs'

nix_shell_nixpkgs_zsh() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: nix_shell_nixpkgs_zsh <pkg> [pkg ...]" >&2
        return 1
    fi

    local -a installables
    local pkg

    for pkg in "$@"; do
        if [[ "$pkg" == *"#"* ]]; then
            installables+=("$pkg")
        else
            installables+=("nixpkgs#$pkg")
        fi
    done

    nix shell "${installables[@]}" -c zsh
}

alias ns='nix_shell_nixpkgs_zsh'
