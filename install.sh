#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="bak.$(date +%Y%m%d%H%M%S)"
NVM_VERSION="${NVM_VERSION:-v0.40.5}"

OS="$(uname -s)"
ARCH="$(uname -m)"

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

fetch() {
  # fetch <url> [output-file]; streams to stdout without an output file.
  if command -v curl >/dev/null 2>&1; then
    if [ $# -gt 1 ]; then curl -fsSL "$1" -o "$2"; else curl -fsSL "$1"; fi
  elif command -v wget >/dev/null 2>&1; then
    if [ $# -gt 1 ]; then wget -qO "$2" "$1"; else wget -qO- "$1"; fi
  else
    info "Install curl or wget, then rerun this script."
    return 1
  fi
}

install_nvm() {
  export NVM_DIR="$HOME/.nvm"

  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    info "Installing nvm $NVM_VERSION"
    mkdir -p "$NVM_DIR"
    PROFILE=/dev/null bash -c "$(fetch "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh")"
  else
    info "nvm already installed"
  fi

  # --no-use: plain sourcing auto-runs `nvm use` against any .nvmrc in the
  # cwd (this repo has one), which exits non-zero before node is installed.
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" --no-use
  nvm install --lts
  nvm alias default 'lts/*'
}

link_node_system() {
  # Dev pods run as root on Linux: link nvm's default node into
  # /usr/local/bin so every context (non-interactive shells, editors,
  # kubectl exec) resolves the same node/npm — no second npm.
  if [ "$(uname -s)" != "Linux" ] || [ "$(id -u)" != "0" ]; then
    return 0
  fi

  local node_path bin_dir tool
  node_path="$(nvm which default 2>/dev/null)" || true
  if [ -z "${node_path:-}" ] || [ ! -x "$node_path" ]; then
    info "No nvm default node to link system-wide; skipping."
    return 0
  fi
  bin_dir="$(dirname "$node_path")"

  for tool in node npm npx corepack; do
    if [ -x "$bin_dir/$tool" ]; then
      ln -sfn "$bin_dir/$tool" "/usr/local/bin/$tool"
    fi
  done
  info "Linked nvm node ($bin_dir) into /usr/local/bin"
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

install_claude() {
  if command -v claude >/dev/null 2>&1; then
    info "Claude Code already installed: $(claude --version 2>/dev/null || true)"
    return 0
  fi
  info "Installing Claude Code"
  fetch https://claude.ai/install.sh | bash
}

install_opencode() {
  if command -v opencode >/dev/null 2>&1 || [ -x "$HOME/.opencode/bin/opencode" ]; then
    info "opencode already installed"
    return 0
  fi
  info "Installing opencode"
  fetch https://opencode.ai/install | bash
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    info "starship already installed"
    return 0
  fi
  info "Installing starship to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  fetch https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
}

install_zsh_plugins() {
  # Only needed where a package manager didn't provide them (Linux).
  local plugin_dir="$HOME/.zsh"
  mkdir -p "$plugin_dir"
  if [ ! -d "$plugin_dir/zsh-autosuggestions" ]; then
    info "Cloning zsh-autosuggestions"
    git clone --quiet --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions"
  fi
  if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
    info "Cloning zsh-syntax-highlighting"
    git clone --quiet --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/zsh-syntax-highlighting"
  fi
}

install_fzf() {
  if command -v fzf >/dev/null 2>&1 || [ -x "$HOME/.fzf/bin/fzf" ]; then
    info "fzf already installed"
    return 0
  fi
  info "Installing fzf to ~/.fzf"
  git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    info "lazygit already installed"
    return 0
  fi
  if [ "$OS" != "Linux" ]; then
    info "Skipping lazygit binary install on $OS (use 'brew bundle')"
    return 0
  fi
  local arch
  case "$ARCH" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) info "Unsupported arch for lazygit: $ARCH"; return 1 ;;
  esac
  local version
  version="$(fetch https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')"
  if [ -z "$version" ]; then
    info "Could not resolve latest lazygit version"
    return 1
  fi
  info "Installing lazygit $version to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  local tmp
  tmp="$(mktemp -d)"
  fetch "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz" "$tmp/lazygit.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  mv "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
}

install_neovim() {
  # LazyVim wants a recent Neovim; distro packages are often too old.
  if [ "$OS" != "Linux" ]; then
    return 0
  fi
  if command -v nvim >/dev/null 2>&1; then
    local minor
    minor="$(nvim --version | head -1 | sed -E 's/^NVIM v[0-9]+\.([0-9]+).*/\1/')"
    if [ "${minor:-0}" -ge 10 ] 2>/dev/null; then
      info "Neovim is recent enough: $(nvim --version | head -1)"
      return 0
    fi
  fi
  local arch
  case "$ARCH" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) info "Unsupported arch for neovim tarball: $ARCH"; return 1 ;;
  esac
  info "Installing latest stable Neovim to ~/.local/opt/nvim"
  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  local tmp
  tmp="$(mktemp -d)"
  fetch "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz" "$tmp/nvim.tar.gz"
  rm -rf "$HOME/.local/opt/nvim"
  tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/opt"
  mv "$HOME/.local/opt/nvim-linux-${arch}" "$HOME/.local/opt/nvim"
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
}

install_tpm() {
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Cloning tmux plugin manager"
    git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

install_monitors() {
  # nvtop (GPU) + btop (system). apt-only, and only when we can install
  # packages (root on a dev pod). Harmless to skip elsewhere.
  if [ "$OS" != "Linux" ] || ! command -v apt-get >/dev/null 2>&1; then
    return 0
  fi
  local sudo_cmd=""
  if [ "$(id -u)" != "0" ]; then
    if ! command -v sudo >/dev/null 2>&1; then
      info "Skipping nvtop/btop (need root or sudo)"
      return 0
    fi
    sudo_cmd="sudo"
  fi
  info "Installing nvtop + btop"
  export DEBIAN_FRONTEND=noninteractive
  $sudo_cmd apt-get install -y -qq nvtop btop >/dev/null 2>&1 || {
    $sudo_cmd apt-get update -qq
    $sudo_cmd apt-get install -y -qq nvtop btop >/dev/null
  }
}

main() {
  link_path "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim"
  link_path "$DOTFILES_DIR/opencode/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
  link_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_path "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
  link_path "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

  if [ "${INSTALL_NODE:-1}" != "0" ]; then
    install_nvm || info "WARN: nvm/node install failed"
    link_node_system || info "WARN: linking node system-wide failed"
  fi

  if [ "${INSTALL_CODEX:-1}" != "0" ]; then
    install_codex || info "WARN: codex install failed"
  fi

  if [ "${INSTALL_CLAUDE:-1}" != "0" ]; then
    install_claude || info "WARN: claude install failed"
  fi

  if [ "${INSTALL_OPENCODE:-1}" != "0" ]; then
    install_opencode || info "WARN: opencode install failed"
  fi

  if [ "${INSTALL_EXTRAS:-1}" != "0" ]; then
    install_starship || info "WARN: starship install failed"
    install_zsh_plugins || info "WARN: zsh plugins install failed"
    install_fzf || info "WARN: fzf install failed"
    install_lazygit || info "WARN: lazygit install failed"
    install_neovim || info "WARN: neovim install failed"
    install_tpm || info "WARN: tpm install failed"
    install_monitors || info "WARN: nvtop/btop install failed"
  fi

  info "Install complete. Restart your shell and restart opencode."
}

main "$@"
