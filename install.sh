#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="bak.$(date +%Y%m%d%H%M%S)"
NVM_VERSION="${NVM_VERSION:-v0.40.5}"

info() {
  printf '%s\n' "$*"
}

link_path() {
  local source_path="$1"
  local target_path="$2"
  local target_dir

  target_dir="$(dirname "$target_path")"
  mkdir -p "$target_dir"

  if [ -L "$target_path" ]; then
    local existing_target
    existing_target="$(readlink "$target_path")"
    if [ "$existing_target" = "$source_path" ]; then
      info "Already linked: $target_path"
      return 0
    fi
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    local backup_path="${target_path}.${BACKUP_SUFFIX}"
    info "Backing up $target_path to $backup_path"
    mv "$target_path" "$backup_path"
  fi

  ln -s "$source_path" "$target_path"
  info "Linked $target_path -> $source_path"
}

install_nvm() {
  export NVM_DIR="$HOME/.nvm"

  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    info "Installing nvm $NVM_VERSION"
    mkdir -p "$NVM_DIR"
    if command -v curl >/dev/null 2>&1; then
      PROFILE=/dev/null bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash"
    elif command -v wget >/dev/null 2>&1; then
      PROFILE=/dev/null bash -c "wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash"
    else
      info "Install curl or wget, then rerun this script."
      return 1
    fi
  else
    info "nvm already installed"
  fi

  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
}

install_codex() {
  if command -v codex >/dev/null 2>&1; then
    info "Codex CLI already installed: $(codex --version 2>/dev/null || true)"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    info "npm is not available; skipping Codex install."
    return 1
  fi

  info "Installing Codex CLI"
  npm install -g @openai/codex
}

main() {
  link_path "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim"
  link_path "$DOTFILES_DIR/opencode/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
  link_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_path "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"

  if [ "${INSTALL_NODE:-1}" != "0" ]; then
    install_nvm
  fi

  if [ "${INSTALL_CODEX:-1}" != "0" ]; then
    install_codex
  fi

  info "Install complete. Restart your shell and restart opencode."
}

main "$@"
