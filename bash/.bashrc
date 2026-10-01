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
