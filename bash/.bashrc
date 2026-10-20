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

# Directory bookmarks: `mark [name]` saves the current directory (name defaults to
# the folder's name), `jump <name>` cds there, `marks` lists them, `unmark <name>` deletes.
# These are functions, not a script: a script runs in a child process, so its cd
# would change the child's directory and leave this shell where it was.
BOOKMARKS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/bookmarks" # one "name path" per line

mark() {
    local name="${1:-${PWD##*/}}"
    if [[ -z $name || $name == *[[:space:]]* ]]; then
        echo "mark: name must be non-empty with no spaces" >&2
        return 1
    fi
    mkdir -p "${BOOKMARKS_FILE%/*}"
    unmark "$name" 2>/dev/null # replace any old bookmark with this name
    echo "$name $PWD" >> "$BOOKMARKS_FILE"
    echo "marked $name -> $PWD"
}

jump() {
    if [[ -z $1 ]]; then
        marks
        return
    fi
    local dir
    # Field 1 is the name; everything after the first space is the path (may contain spaces)
    dir=$(awk -v n="$1" '$1 == n { sub(/^[^ ]+ /, ""); print; exit }' "$BOOKMARKS_FILE" 2>/dev/null)
    if [[ -z $dir ]]; then
        echo "jump: no bookmark '$1' (see: marks)" >&2
        return 1
    fi
    if [[ ! -d $dir ]]; then
        echo "jump: '$1' points to $dir, which no longer exists (remove it: unmark $1)" >&2
        return 1
    fi
    cd "$dir"
}

marks() {
    [[ -f $BOOKMARKS_FILE ]] && awk '{ n = $1; sub(/^[^ ]+ /, ""); printf "%-15s %s\n", n, $0 }' "$BOOKMARKS_FILE"
}

unmark() {
    [[ -f $BOOKMARKS_FILE ]] || return 1
    awk -v n="$1" '$1 != n' "$BOOKMARKS_FILE" > "$BOOKMARKS_FILE.tmp" && mv "$BOOKMARKS_FILE.tmp" "$BOOKMARKS_FILE"
}

# Tab-complete bookmark names after jump/unmark
_bookmark_names() {
    COMPREPLY=($(compgen -W "$(awk '{ print $1 }' "$BOOKMARKS_FILE" 2>/dev/null)" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _bookmark_names jump unmark
