function t() {
    local selected selected_name tmux_running

    # If an session is passed, use it
    if [[ $# -eq 1 ]]; then
        selected=$1
    else
        local -a candidates
        local -a manual=()
        [[ -d "$HOME/nix-config" ]] && manual+=("$HOME/nix-config")
        [[ -d "$HOME/nix-secrets" ]] && manual+=("$HOME/nix-secrets")
        [[ -d "$HOME/.config" ]] && manual+=("$HOME/.config")

        [[ -d "$HOME/Code" ]] && candidates+=("${(@f)$(find "$HOME/Code" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)}")
        [[ -d "$HOME/Code/surge" ]] && candidates+=("${(@f)$(find "$HOME/Code/surge" -mindepth 1 -maxdepth 2 -type d ! -name '.*' 2>/dev/null)}")
        [[ -d "$HOME/Code/fork" ]] && candidates+=("${(@f)$(find "$HOME/Code/fork" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)}")
        [[ -d "$HOME/Code/koano" ]] && candidates+=("${(@f)$(find "$HOME/Code/koano" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)}")
        [[ -d "$HOME/Code/freelance" ]] && candidates+=("${(@f)$(find "$HOME/Code/freelance" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)}")

        # Combine and fzf
        selected=$(
            printf '%s\n' "${manual[@]}" "${candidates[@]}" \
                | fzf --reverse --border \
                --preview-window=right:60% \
                --preview 'if command -v eza >/dev/null 2>&1; then eza --color=always --tree --level=2 --group-directories-first {} | head -50; elif command -v exa >/dev/null 2>&1; then exa --color=always --tree --level=2 --group-directories-first {} | head -50; else ls -la {} | head -50; fi'
        )
    fi

    # Exit if nothing selected
    [[ -z $selected ]] && return 0

    # Derive a safe session name
    selected_name=$(basename -- "$selected" | tr '.' '_')
    tmux_running=$(pgrep tmux)

    # If no tmux server at all, start a fresh session
    if [[ -z $TMUX && -z $tmux_running ]]; then
        tmux new-session -s $selected_name -c "$selected"
        return
    fi

    # Create detached session if it doesn't exist
    if ! tmux has-session -t="$selected_name" 2>/dev/null; then
        tmux new-session -ds "$selected_name" -c "$selected"
    fi

    # Attach or switch
    if [[ -z $TMUX ]]; then
        tmux attach-session -t "$selected_name"
    else
        tmux switch-client -t "$selected_name"
    fi
}

function ts() {
    local selected

    selected=$(
        tmux list-sessions -F "#{session_name}" 2>/dev/null \
            | fzf --reverse --border \
            --preview 'tmux list-windows -t {}'
    )

    [[ -z "$selected" ]] && return 0

    if [[ -n $TMUX ]]; then
        tmux switch-client -t "$selected"
    else
        tmux attach-session -t "$selected"
    fi
}
