# Dotfiles

Personal dotfiles for macOS and Linux. The repo is intentionally small and portable: it does not require Homebrew or GNU Stow to install.

## What Is Included

- LazyVim config from `~/.config/nvim`
- opencode privacy config with sharing disabled and OpenTelemetry off
- Portable zsh config for macOS and Linux
- `nvm` bootstrap with latest Node LTS
- Codex CLI install through npm after Node is available
- Optional `Brewfile` for macOS package convenience

## Install

Clone the repo and run:

```sh
./install.sh
```

The installer symlinks files into your home directory. If a destination already exists and is not the expected symlink, it is moved aside with a `.bak.<timestamp>` suffix first.

By default the installer also installs `nvm`, installs the latest Node LTS, sets it as the default, and installs Codex CLI globally with npm.

To skip Node or Codex:

```sh
INSTALL_NODE=0 ./install.sh
INSTALL_CODEX=0 ./install.sh
```

## Linux Notes

Install these packages with your distro package manager before running the installer:

- `git`
- `curl` or `wget`
- `zsh`
- `neovim`

Examples:

```sh
sudo apt install git curl zsh neovim
sudo dnf install git curl zsh neovim
sudo pacman -S git curl zsh neovim
```

## macOS Notes

Homebrew is optional. If it is available, `zsh/.zshrc` and `zsh/.zprofile` load it automatically.

To install the optional package list:

```sh
brew bundle
```

## Codex

Codex is installed with:

```sh
npm install -g @openai/codex
```

This repo does not track `~/.codex` because it contains auth tokens, sessions, caches, SQLite state, local app paths, and project trust data. After bootstrap, run `codex` and sign in on each machine.

## opencode Privacy

The repo configures two layers:

- `~/.config/opencode/opencode.json` sets `share` to `disabled` and `experimental.openTelemetry` to `false`.
- `~/.zshrc` exports `DO_NOT_TRACK=1` and `OPENCODE_DISABLE_SHARE=1`.

Restart opencode after installing these dotfiles so it reloads the config.
