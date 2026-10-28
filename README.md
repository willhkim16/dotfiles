# dotfiles

My Arch Linux + KDE Plasma config, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level folder is a Stow package that mirrors its path under `~`, so `stow bash` symlinks `~/.bashrc -> ~/dotfiles/bash/.bashrc`.

| Package | Configures |
| --- | --- |
| `bash` | prompt, `PATH`, ssh-agent socket fallback for SSH/TTY logins |
| `git` | identity, `delta` pager, `pull.rebase`, global ignores |
| `ssh` | host nicknames, NYU CIMS gateway with connection reuse (private hosts and my NetID go in an untracked `~/.ssh/config.local`, which the config includes), agent key caching, `environment.d` file pointing the whole desktop session at the ssh-agent |
| `vim` | line numbers, search, per-language plugins and indenting, OCaml tooling via opam |
| `alacritty` | terminal colors and keybindings |
| `fontconfig` | prefer Noto Color Emoji over the monochrome Noto Sans Symbols 2 for emoji in monospace, so emoji render in color in Alacritty |
| `mime` | `default-apps`, which sets VS Code as the default app for code and config file types (Python, C/C++, JSON, YAML, ...) and leaves every other association in `mimeapps.list` alone, since that file also holds machine-specific entries |
| `kwin` | `kwin-rules`, a script that rebuilds KDE's `kwinrulesrc` from the rules it declares, so the script is the single source of truth (rules made in System Settings get wiped) |
| `backup` | `backup`, which mounts the external backup drive by UUID and rsyncs the whole system onto it, stopping before any copy if the drive isn't there; PC only, since the UUID is that drive's |
| `claude` | Claude Code settings: Opus at high effort, dark theme, plugins (`frontend-design`, `rust-analyzer-lsp`, `pyright-lsp`); and the global `CLAUDE.md` (tutoring by default, with per-project build mode, and commit message rules) |
| `vscode` | VS Code settings (SML: format with `smlfmt` on save, Millet's inline type hints hidden unless Ctrl+Alt is held) and `update-vscode`, which builds the official VS Code (`visual-studio-code-bin`, needed for Remote-SSH) from its AUR recipe after showing what changed in it, since `pacman -Syu` doesn't update it; `extensions.txt` lists the extensions I chose (their extension-pack members install automatically) |

## Install on a new machine

```sh
sudo pacman -S git stow git-delta noto-fonts-emoji # .gitconfig uses delta as its pager; git errors without it. The fontconfig rule needs the emoji font
git clone git@github.com:willhkim16/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -nv --no-folding bash git ssh vim alacritty fontconfig vscode claude   # dry run: read what it would do
stow -v  --no-folding bash git ssh vim alacritty fontconfig vscode claude
mkdir -p ~/.ssh/sockets                            # used by the CIMS ControlPath
scp willkim@<PC-tailscale-IP>:.ssh/config.local ~/.ssh/   # private hosts (the willkim-arch alias lives in this file, so use the IP)
systemctl --user enable --now ssh-agent.socket     # the agent environment.d points at; log out and back in once
update-vscode                                      # first run clones the AUR recipe and prints it; read it before answering y
xargs -n1 code --install-extension < extensions.txt
stow -v --no-folding mime && default-apps          # open code files in VS Code
stow -v --no-folding kwin && kwin-rules            # only on a machine with the same monitors (rules are for DP-3)
stow -v --no-folding backup                        # only on the PC (mounts its backup drive by UUID)
```

`--no-folding` makes Stow link individual files, never whole folders, so files other programs create (e.g. in `~/.local/bin`) don't land in the repo.
Stow refuses to replace a real file that's already there. Move the existing file aside (or diff it against the repo copy), then stow again.
