#!/bin/sh

picker=${TM_PICKER:-"fzf"}
dirs=${TM_SRCS}
presets=${TM_LAYOUTS_DIR:-"${XDG_DATA_HOME:-$HOME/.local/share}/tmux-companion"}

: "${TM_PRESENTS:=true}"

die() { printf '%s: %s.\n' "$0" "$1" >&2; exit 1; }
# Searches for all non hidden directories
get_dirs() { find $dirs -mindepth 1 -maxdepth 1 -type d | sed "/\.[^\.]*/d"; }
run_preset() { "$TM_PRESENTS" && [ -r "$2" ] && tmux send-keys -t "$1" ". $2" Enter; }

main() {
    case "$1" in
        "")
            [ -z "$dirs" ] && die "You need to set the TMS_SRCS env variable"
            selected=$(get_dirs | "$picker")
            ;;
        .)
            selected="$PWD"
            ;;
        *)
            selected="$1"
            ;;
    esac

    [ -z "$selected" ] && exit 0

    selected_base=$(basename "$selected")
    # Getting first 8 caracters of name for preventing tmux to truncate the
    # name label box.
    # If you have the directory name "tmux-companion" tmux will truncate at the
    # 9th line like so: '[tmux-comp'. If instead we take the first 8 characters
    # will become something like this: '[tmux-com]'
    selected_name=$(basename "$selected" | tr . _ | head -c8)


    if [ -n "$TMUX" ]; then # If in tmux
        tmux has-session -t "$selected_name" 2>/dev/null \
            || tmux new-session -ds "$selected_name" -c "$selected"
        tmux switch-client -t "$selected_name"
    elif [ -z "$TMUX" ]; then # If outside of tmux
        tmux has-session -t "$selected_name" 2>/dev/null \
            || tmux new-session -s "$selected_name" -c "$selected"
        tmux attach -t "$selected_name"
    fi
    run_preset "$selected_base" "$presets/$selected.preset"
}

main "$@"
