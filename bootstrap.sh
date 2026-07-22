#!/usr/bin/env bash
# Dev pod / fresh Linux bootstrap: installs base packages, makes zsh the
# login shell, then runs install.sh. Dev pod tooling (e.g. intertubin) runs
# this automatically on first pod start; safe to re-run.
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then
  SUDO=""
  if [ "$(id -u)" != "0" ]; then
    command -v sudo >/dev/null 2>&1 && SUDO="sudo"
  fi
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -qq || true
  $SUDO apt-get install -y -qq \
    git curl wget unzip zsh tmux ripgrep fzf jq htop build-essential \
    >/dev/null || echo "WARN: base package install incomplete"

  # Make zsh the login shell so ssh sessions land in the configured shell.
  if command -v zsh >/dev/null 2>&1 && command -v chsh >/dev/null 2>&1; then
    $SUDO chsh -s "$(command -v zsh)" "$(whoami)" 2>/dev/null \
      || echo "WARN: could not change login shell to zsh"
  fi
fi

bash "$DOTFILES_DIR/install.sh"
