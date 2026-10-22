#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Colors (24-bit RGB)
USERNAME_COLOR="\[\e[38;2;21;244;238m\]" # Sky Blue
AT_COLOR="\[\e[38;2;255;255;0m\]" # Neon Yellow
HOST_COLOR="\[\e[38;2;255;0;169m\]" # Neon Pink
RESET_COLOR="\[\e[0m\]"

# Prompt. \\$ prints # as root, $ otherwise (a single \ would be eaten by the double quotes)
PS1="[${USERNAME_COLOR}\u${AT_COLOR}@${HOST_COLOR}\h${RESET_COLOR} \w]\\$ "

# Directory bookmarks: `mark [name]` saves the current directory, `jump <name>` cds
# there. -h on either shows all options.
# These are functions, not a script: a script runs in a child process, so its cd
# would change the child's directory and leave this shell where it was.
BOOKMARKS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/bookmarks" # one "name path" per line

_bookmarks_help() {
    cat <<'HELP'
Directory bookmarks:
  mark [name]      bookmark the current directory (name defaults to the folder's name)
  mark -d <name>   delete a bookmark
  jump <name>      cd to a bookmark (Tab completes names)
  jump [-l]        list all bookmarks
  -h, --help       show this help (on either command)
HELP
    echo "Stored in $BOOKMARKS_FILE"
}

# Print the path saved under name $1. Field 1 is the name; everything after the
# first space is the path (which may contain spaces).
_bookmark_path() {
    awk -v n="$1" '$1 == n { sub(/^[^ ]+ /, ""); print; exit }' "$BOOKMARKS_FILE" 2>/dev/null
}

_bookmark_delete() {
    [[ -f $BOOKMARKS_FILE ]] || return
    awk -v n="$1" '$1 != n' "$BOOKMARKS_FILE" > "$BOOKMARKS_FILE.tmp" && mv "$BOOKMARKS_FILE.tmp" "$BOOKMARKS_FILE"
}

mark() {
    case $1 in
        -h|--help) _bookmarks_help; return ;;
        -d)
            if [[ -z $2 || -z $(_bookmark_path "$2") ]]; then
                echo "mark: no bookmark '$2' (list them: jump -l)" >&2
                return 1
            fi
            _bookmark_delete "$2"
            echo "deleted $2"
            return ;;
        -*) echo "mark: unknown option '$1' (see: mark -h)" >&2; return 1 ;;
    esac
    local name="${1:-${PWD##*/}}"
    if [[ -z $name || $name == *[[:space:]]* ]]; then
        echo "mark: name must be non-empty with no spaces" >&2
        return 1
    fi
    mkdir -p "${BOOKMARKS_FILE%/*}"
    _bookmark_delete "$name" # replace any old bookmark with this name
    echo "$name $PWD" >> "$BOOKMARKS_FILE"
    echo "marked $name -> $PWD"
}

jump() {
    case $1 in
        -h|--help) _bookmarks_help; return ;;
        -l|'')
            [[ -f $BOOKMARKS_FILE ]] && awk '{ n = $1; sub(/^[^ ]+ /, ""); printf "%-15s %s\n", n, $0 }' "$BOOKMARKS_FILE"
            return ;;
        -*) echo "jump: unknown option '$1' (see: jump -h)" >&2; return 1 ;;
    esac
    local dir
    dir=$(_bookmark_path "$1")
    if [[ -z $dir ]]; then
        echo "jump: no bookmark '$1' (list them: jump -l)" >&2
        return 1
    fi
    if [[ ! -d $dir ]]; then
        echo "jump: '$1' points to $dir, which no longer exists (remove it: mark -d $1)" >&2
        return 1
    fi
    cd "$dir" || return # return, not exit: exit would close the terminal
}

# Tab-complete bookmark names after `jump` and `mark -d`.
# bash passes $1 = command, $2 = word being completed, $3 = the word before it.
_bookmark_complete() {
    if [[ $1 == jump || $3 == -d ]]; then
        # mapfile puts one match per array entry. COMPREPLY=($(...)) would also glob-expand
        # them, so a bookmark named * would complete to the files in the current folder.
        mapfile -t COMPREPLY < <(compgen -W "$(awk '{ print $1 }' "$BOOKMARKS_FILE" 2>/dev/null)" -- "$2")
    fi
}
complete -F _bookmark_complete jump mark
