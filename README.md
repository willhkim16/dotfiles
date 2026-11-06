# dotfiles

My Arch Linux + KDE Plasma config, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a Stow package that mirrors its path under `~`.
For example, `stow bash` symlinks `~/.bashrc -> ~/dotfiles/bash/.bashrc`.

## Packages

| Package | What it configures |
| --- | --- |
| `bash` | Prompt, `PATH`, ssh-agent socket fallback for SSH/TTY logins |
| `git` | Identity, `delta` pager, `pull.rebase`, global ignores |
| `ssh` | Host nicknames, NYU CIMS gateway, agent key caching |
| `vim` | Line numbers, search, per-language plugins and indenting, OCaml tooling via opam |
| `alacritty` | Terminal colors and keybindings |
| `fontconfig` | Color emoji in the terminal |
| `mime` | `default-apps` script: VS Code as the default app for code files |
| `kwin` | `kwin-rules` script: KDE window rules as code |
| `discordify` | `discordify` script: shrink a clip under Discord's upload limit |
| `backup` | `backup` script: rsync the whole system to the external drive |
| `claude` | Claude Code settings and global `CLAUDE.md` |
| `vscode` | VS Code settings, `update-vscode` script, extension list |

### Notes on the less obvious ones

**`ssh`.** Private hosts and my NetID live in an untracked `~/.ssh/config.local`, which the tracked config includes.
The CIMS gateway uses connection reuse (`ControlPath`).
An `environment.d` file points the whole desktop session at the ssh-agent, not just shells.

**`fontconfig`.** Prefers Noto Color Emoji over the monochrome Noto Sans Symbols 2 for emoji in monospace fonts, so emoji render in color in Alacritty.

**`mime`.** `default-apps` sets VS Code as the handler for code and config file types (Python, C/C++, JSON, YAML, ...).
It leaves every other entry in `mimeapps.list` alone, since that file also holds machine-specific associations.

**`kwin`.** `kwin-rules` rebuilds KDE's `kwinrulesrc` from the rules it declares, so the script is the single source of truth.
Rules made in System Settings get wiped on the next run.

**`discordify`.** Two-pass encodes a clip to 720p H.264 at whatever bitrate lands the file under a size target.
The default target is 19 MB, Discord's free-tier limit.
HDR sources are tone-mapped to SDR, and the output is always 8-bit, since Discord's player decodes nothing else.

```sh
discordify clip.mp4 [target_MB]   # writes clip_discord.mp4 next to the input
```

**`backup`.** Mounts the external backup drive by UUID and rsyncs the whole system onto it.
It stops before copying anything if the drive isn't there.
PC only, since the UUID is that drive's.

**`claude`.** Fable as the default model, Opus at high effort, dark theme, and the plugins `frontend-design`, `rust-analyzer-lsp`, and `pyright-lsp`.
The global `CLAUDE.md` sets tutoring as the default, with a per-project build mode, and commit message rules.

**`vscode`.** Settings for SML: format with `smlfmt` on save, and hide Millet's inline type hints unless Ctrl+Alt is held.
`update-vscode` builds the official VS Code (`visual-studio-code-bin`, needed for Remote-SSH) from its AUR recipe, after showing what changed in the recipe, since `pacman -Syu` doesn't update it.
`extensions.txt` lists the extensions I chose; their extension-pack members install automatically.

## Install on a new machine

### 1. Prerequisites

```sh
sudo pacman -S git stow git-delta noto-fonts-emoji
git clone git@github.com:willhkim16/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

`.gitconfig` uses `delta` as its pager and git errors without it.
The fontconfig rule needs `noto-fonts-emoji`.

### 2. Stow the portable packages

Dry run first and read what Stow would do, then run it for real.

```sh
stow -nv --no-folding bash git ssh vim alacritty fontconfig vscode claude discordify
stow -v  --no-folding bash git ssh vim alacritty fontconfig vscode claude discordify
```

`--no-folding` makes Stow link individual files, never whole folders.
Without it, files other programs create (e.g. in `~/.local/bin`) would land in the repo.

Stow refuses to replace a real file that's already there.
Move the existing file aside, or diff it against the repo copy, then stow again.

### 3. Finish SSH setup

```sh
mkdir -p ~/.ssh/sockets                                  # the CIMS ControlPath lives here
scp willkim@<PC-tailscale-IP>:.ssh/config.local ~/.ssh/  # private hosts
systemctl --user enable --now ssh-agent.socket           # the agent environment.d points at
```

Use the PC's IP in the `scp` line, because the `willkim-arch` alias is defined in the very file you're copying.
Log out and back in once so the session picks up the ssh-agent environment.

### 4. VS Code

```sh
update-vscode
xargs -n1 code --install-extension < extensions.txt
```

The first run of `update-vscode` clones the AUR recipe and prints it.
Read it before answering `y`.

### 5. Machine-specific packages

Only stow these where they apply.

```sh
stow -v --no-folding mime && default-apps   # any machine: open code files in VS Code
stow -v --no-folding kwin && kwin-rules     # same monitors only (rules are for DP-3)
stow -v --no-folding backup                 # PC only (mounts its backup drive by UUID)
```
