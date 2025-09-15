function t() {
    local selected selected_name tmux_running

    # If an session is passed, use it
    if [[ $# -eq 1 ]]; then
        selected=$1
    else
        local manual=("$HOME/nix-config" "$HOME/.config")
        local code=$(find ~/Code -mindepth 1 -maxdepth 1 -type d)
        local surge=$(find ~/Code/surge -mindepth 1 -maxdepth 2 -type d)
        local fork=$(find ~/Code/fork -mindepth 1 -maxdepth 1 -type d)
        local koano=$(find ~/Code/koano -mindepth 1 -maxdepth 1 -type d)
        local freelance=$(find ~/Code/freelance -mindepth 1 -maxdepth 2 -type d)

        # Combine and fzf
        selected=$(
            printf '%s\n' "${manual[@]}" "${code[@]}" "${surge[@]}" "${fork[@]}" "${koano[@]}" "${freelance[@]}" \
                | fzf --reverse --border \
                --preview-window=right:60% \
                --preview 'exa --color=always --tree --level=2 --group-directories-first {} | head -50'
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
