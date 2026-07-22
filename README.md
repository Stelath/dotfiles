# Dotfiles

Personal dotfiles for macOS and Linux (including GPU dev pods). The repo is
intentionally small and portable: it does not require Homebrew or GNU Stow to
install.

## What Is Included

- LazyVim config from `~/.config/nvim` (a recent Neovim is installed on Linux
  automatically when the system one is older than 0.10)
- opencode privacy config with sharing disabled and OpenTelemetry off
- Portable zsh config for macOS and Linux with starship, zsh-autosuggestions,
  zsh-syntax-highlighting, and fzf keybindings (ctrl-r history, ctrl-t files)
- tmux config with tpm (mouse on, big scrollback, vi copy mode)
- `nvm` bootstrap with latest Node LTS
- Agent CLIs: Claude Code, Codex, and opencode
- lazygit, plus nvtop/btop system monitors on apt-based Linux
- Optional `Brewfile` for macOS package convenience

## Install

Clone the repo and run:

```sh
./install.sh
```

The installer symlinks files into your home directory. If a destination
already exists and is not the expected symlink, it is moved aside with a
`.bak.<timestamp>` suffix first.

By default the installer also installs `nvm` + latest Node LTS, Codex CLI,
Claude Code, opencode, and the extras (starship, zsh plugins, fzf, lazygit,
Neovim when needed, tpm, nvtop/btop). Each group can be skipped:

```sh
INSTALL_NODE=0 ./install.sh      # skip nvm/node
INSTALL_CODEX=0 ./install.sh     # skip Codex CLI
INSTALL_CLAUDE=0 ./install.sh    # skip Claude Code
INSTALL_OPENCODE=0 ./install.sh  # skip opencode
INSTALL_EXTRAS=0 ./install.sh    # skip starship/zsh plugins/fzf/lazygit/nvim/tpm/monitors
```

## Dev Pods / Fresh Linux

`bootstrap.sh` is the entry point used by dev pod tooling (it runs
automatically when a pod is created with these dotfiles): it installs base
apt packages (git, curl, zsh, tmux, ripgrep, fzf, jq, ...), switches the
login shell to zsh, and then runs `install.sh`.

```sh
./bootstrap.sh
```

## Linux Notes

`bootstrap.sh` handles apt-based distros. On others, install these first:

- `git`
- `curl` or `wget`
- `zsh`

## macOS Notes

Homebrew is optional. If it is available, `zsh/.zshrc` and `zsh/.zprofile`
load it automatically.

To install the optional package list:

```sh
brew bundle
```

## Agent CLIs

- **Codex** is installed with `npm install -g @openai/codex`. This repo does
  not track `~/.codex` because it contains auth tokens, sessions, caches,
  SQLite state, local app paths, and project trust data. After bootstrap, run
  `codex` and sign in on each machine.
- **Claude Code** is installed with the official installer
  (`curl -fsSL https://claude.ai/install.sh | bash`). `~/.claude` is not
  tracked for the same reason; run `claude` and sign in per machine.
- **opencode** is installed with the official installer
  (`curl -fsSL https://opencode.ai/install | bash`); its config is tracked
  (see below), its state (`~/.opencode`) is not.

## opencode Privacy

The repo configures two layers:

- `~/.config/opencode/opencode.json` sets `share` to `disabled` and
  `experimental.openTelemetry` to `false`.
- `~/.zshrc` exports `DO_NOT_TRACK=1` and `OPENCODE_DISABLE_SHARE=1`.

The global opencode config also sets conservative permissions:

- Ask before edits and most shell commands.
- Allow a small set of exact read-only git inspection commands like
  `git status`, `git diff`, and `git log`.
- Deny model/tool access to common secret-bearing directories like `~/.ssh`,
  `~/.aws`, `~/.config/gh`, `~/.codex`, and `~/.opencode`.

Restart opencode after installing these dotfiles so it reloads the config.
