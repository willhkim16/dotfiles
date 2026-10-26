#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Editor for programs that open one (sudoedit, crontab -e). Their fallback, vi, isn't installed.
export EDITOR=vim

# Prompt, on two lines so a long path never shortens the space you type in:
#   user@host ~/some/dir (main *=) exit 1
#   $
# The git part only shows inside a repo, and "exit N" only after a failed command.

# Prompt colors: 24-bit RGB foreground escapes, \e[38;2;R;G;Bm. The \[ \] around each
# one tell bash it takes no screen space; without them bash miscounts the prompt's
# width and long command lines wrap wrong. Single quotes keep every backslash as is.
_prompt_user='\[\e[38;2;21;244;238m\]' # sky blue
_prompt_at='\[\e[38;2;255;255;0m\]'    # neon yellow
_prompt_host='\[\e[38;2;255;0;169m\]'  # neon pink
_prompt_path='\[\e[1m\]'               # bold
_prompt_error='\[\e[38;2;255;85;85m\]' # red
_prompt_reset='\[\e[0m\]'

# __git_ps1 ships with git. Its options add symbols after the branch name:
source /usr/share/git/completion/git-prompt.sh 2>/dev/null
GIT_PS1_SHOWDIRTYSTATE=1     # * unstaged changes, + staged changes
GIT_PS1_SHOWUNTRACKEDFILES=1 # % untracked files
GIT_PS1_SHOWUPSTREAM=auto    # < behind, > ahead, <> diverged, = up to date with the remote
GIT_PS1_SHOWCOLORHINTS=1     # branch turns green when clean, red when dirty

# Rebuild PS1 before every prompt, since the git state and exit status change.
_set_prompt() {
    local status=$? # must come first: every command after this overwrites $?
    local before="${_prompt_user}\u${_prompt_at}@${_prompt_host}\h${_prompt_reset} ${_prompt_path}\w${_prompt_reset}"
    local after=''
    ((status)) && after+=" ${_prompt_error}exit ${status}${_prompt_reset}"
    after+='\n\$ ' # \$ prints # as root, $ otherwise
    if declare -F __git_ps1 >/dev/null; then
        __git_ps1 "$before" "$after" ' (%s)' # sets PS1 to before + branch info + after
    else
        PS1=$before$after
    fi
    return "$status" # pass $? on to the PROMPT_COMMAND entries that run after this one
}
# PROMPT_COMMAND is a list (/etc/bash.bashrc puts a window-title command in it), so add
# to it rather than replacing it. _set_prompt goes first so it sees the command's real $?.
# The check stops `source ~/.bashrc` from adding it twice.
[[ " ${PROMPT_COMMAND[*]} " == *" _set_prompt "* ]] || PROMPT_COMMAND=(_set_prompt "${PROMPT_COMMAND[@]}")

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
