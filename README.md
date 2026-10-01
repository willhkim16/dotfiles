# dotfiles

My Arch Linux + KDE Plasma config, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level folder is a Stow package that mirrors its path under `~`, so `stow bash` symlinks `~/.bashrc -> ~/dotfiles/bash/.bashrc`.

| Package | Configures |
| --- | --- |
| `bash` | prompt, `PATH`, ssh-agent socket |
| `git` | identity, `delta` pager, `pull.rebase`, global ignores |
| `ssh` | host nicknames, NYU CIMS gateway with connection reuse, agent key caching |
| `vim` | line numbers, search, OCaml tooling via opam |
| `alacritty` | terminal colors and keybindings |
| `kwin` | `kwin-rules`, a script that declares KDE window rules (version the script, not KDE's generated `kwinrulesrc`) |
| `vscode` | Code - OSS settings; `extensions.txt` lists extensions |

## Install on a new machine

```sh
sudo pacman -S git stow
git clone git@github.com:willhkim16/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -nv bash git ssh vim alacritty kwin vscode   # dry run: read what it would do
stow -v  bash git ssh vim alacritty kwin vscode
mkdir -p ~/.ssh/sockets                            # used by the CIMS ControlPath
xargs -n1 code --install-extension < extensions.txt
kwin-rules                                         # apply window rules
```

Stow refuses to replace a real file that's already there. Move the existing file aside (or diff it against the repo copy), then stow again.
