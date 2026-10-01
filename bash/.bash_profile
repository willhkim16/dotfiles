#
# ~/.bash_profile
#

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.mpl/bin:$PATH"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
[[ -f ~/.bashrc ]] && . ~/.bashrc


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
test -r '/home/willkim/.opam/opam-init/init.sh' && . '/home/willkim/.opam/opam-init/init.sh' > /dev/null 2> /dev/null || true
# END opam configuration
