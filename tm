#!/bin/sh

picker=${TM_PICKER:-"fzf"}
dirs=${TM_SRCS}
presets=${TM_TEMPLATES_DIR:-"${XDG_DATA_HOME:-$HOME/.local/share}/tmux-companion"}

: "${TM_TEMPLATES:=true}"

die() {
    printf '%s: %s.\n' "$0" "$1" >&2
    exit 1
}
# Searches for all non hidden directories
get_dirs() { find $dirs -mindepth 1 -maxdepth 1 -type d; }
run_template() { "$TM_TEMPLATES" && [ -r "$2" ] && tmux send-keys -t "$1" ". $2" Enter; }

help() {
    less <<EOF
NAME
    tm - tmux companion

SYNOPSIS
    usage: tm [OPTIONS] [DIRECTORY|NAME]

OPTIONS
    -h, --help
        display help

    -t, --template
        create or edit a template file for a specified directory or arbitrary
        name or, if no arguments are given, the current working directory will
        be used

ENVIROMENT
    The script is configured and customized through enviroment variables.

    TM_SRCS: space separetad list of directories where tm's will let you choose
    when called with no arguments (default:"")

    TM_PICKER: fuzzy finder/picker for selecting directories from from your
    TM_SRCS (default:"fzf")

    TM_TEMPLATES: disable templates capabilities

    TM_TEMPLATES_DIR: where tm searches for directory templates (default:"\$XDG_DATA_HOME/tmux-companion/")
EOF
}

gen_template() {
    cat <<EOF >"$target"
#!/bin/sh
# Welcome to the default preset for tmux-companion. As you can see this is a
# POSIX shellscript but you can use whatever POSIX compatible shell language
# you'd like.

###############################################################################
# BE CAREFULL THIS CAN DESTROY YOUR SYSTEM IF YOU DON'T KNOW WHAT YOU ARE DOING
###############################################################################

# This is here to prevent re-executon when switching between sessions
if [ -z "\$TM_LOCK_$basename" ] && [ -n "\$TMUX" ]; then
    export TM_LOCK_$basename=1
fi

# You can run whatever tmux command you want:
# tmux new-window -d top
# tmux spilt-window python3
# tmux spilt-window ipython
EOF
}

edit_template() {
    target="$presets/${1:-${PWD##*/}}.presets"
    basename=$(basename "$target" | tr '[:lower:]' '[:upper:]' | tr '-' '_' | cut -d'.' -f1)
    if [ -d "$presets" ]; then
        ! [ -f "$target" ] \
            && gen_template
        ${EDITOR:-vi} "$target"
    else
        die "$presets directory doesn't exitst"
    fi
}

main() {
    case "$1" in
        "")
            [ -z "$dirs" ] && die "You need to set the TMS_SRCS env variable"
            selected=$(get_dirs | "$picker")
            ;;
        -h | --help)
            help
            exit 0
            ;;
        -t | --template)
            edit_template "$2"
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
    run_template "$selected_base" "$presets/$selected.preset"
}

main "$@"
