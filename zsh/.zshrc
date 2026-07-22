# Homebrew is optional. Load it only on machines where it exists.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv zsh)"
fi

# User-local binaries.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) export PATH="$HOME/bin:$PATH" ;;
esac

if [ -d "$HOME/.opencode/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.opencode/bin:"*) ;;
    *) export PATH="$HOME/.opencode/bin:$PATH" ;;
  esac
fi

if [ -d "$HOME/.fzf/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.fzf/bin:"*) ;;
    *) export PATH="$HOME/.fzf/bin:$PATH" ;;
  esac
fi

# Prompt.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Autosuggestions, installed path varies by OS/package manager.
for _zsh_autosuggest in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  if [ -r "$_zsh_autosuggest" ]; then
    source "$_zsh_autosuggest"
    break
  fi
done
unset _zsh_autosuggest

# fzf keybindings (ctrl-r history, ctrl-t files) and completion.
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    # Older fzf packages ship the scripts on disk instead.
    for _fzf_bindings in \
      /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
      /usr/local/opt/fzf/shell/key-bindings.zsh \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      "$HOME/.fzf/shell/key-bindings.zsh"; do
      if [ -r "$_fzf_bindings" ]; then
        source "$_fzf_bindings"
        break
      fi
    done
    unset _fzf_bindings
  fi
fi

# nvm. The install script places nvm here on macOS and Linux.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Privacy defaults for AI CLIs that honor these environment variables.
export DO_NOT_TRACK=1
export OPENCODE_DISABLE_SHARE=1

# Syntax highlighting must be sourced last.
for _zsh_highlight in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  if [ -r "$_zsh_highlight" ]; then
    source "$_zsh_highlight"
    break
  fi
done
unset _zsh_highlight
