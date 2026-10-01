# dotfiles

My Arch Linux + KDE Plasma config, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level folder is a Stow package that mirrors its path under `~`, so `stow bash` symlinks `~/.bashrc -> ~/dotfiles/bash/.bashrc`.

| Package | Configures |
| --- | --- |
| `bash` | prompt, `PATH`, ssh-agent socket fallback for SSH/TTY logins |
| `git` | identity, `delta` pager, `pull.rebase`, global ignores |
| `ssh` | host nicknames, NYU CIMS gateway with connection reuse, agent key caching, `environment.d` file pointing the whole desktop session at the ssh-agent |
| `vim` | line numbers, search, OCaml tooling via opam |
| `alacritty` | terminal colors and keybindings |
| `kwin` | `kwin-rules`, a script that rebuilds KDE's `kwinrulesrc` from the rules it declares, so the script is the single source of truth (rules made in System Settings get wiped) |
| `vscode` | VS Code settings and `update-vscode`, which builds the official VS Code (`visual-studio-code-bin`, needed for Remote-SSH) from its AUR recipe after showing what changed in it, since `pacman -Syu` doesn't update it; `extensions.txt` lists the extensions I chose (their extension-pack members install automatically) |

## Install on a new machine

```sh
sudo pacman -S git stow git-delta                  # .gitconfig uses delta as its pager; git errors without it
git clone git@github.com:willhkim16/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -nv --no-folding bash git ssh vim alacritty vscode   # dry run: read what it would do
stow -v  --no-folding bash git ssh vim alacritty vscode
mkdir -p ~/.ssh/sockets                            # used by the CIMS ControlPath
systemctl --user enable --now ssh-agent.socket     # the agent environment.d points at; log out and back in once
update-vscode                                      # first run clones the AUR recipe and prints it; read it before answering y
xargs -n1 code --install-extension < extensions.txt
stow -v --no-folding kwin && kwin-rules            # only on a machine with the same monitors (rules are for DP-3)
```

`--no-folding` makes Stow link individual files, never whole folders, so files other programs create (e.g. in `~/.local/bin`) don't land in the repo.
Stow refuses to replace a real file that's already there. Move the existing file aside (or diff it against the repo copy), then stow again.
