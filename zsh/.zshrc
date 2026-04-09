# Alacritty-scoped interactive Zsh config.

[[ -o interactive ]] || return 0

if [[ ! -o login && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi

typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
HIST_STAMPS='mm/dd/yyyy'
ZSH_THEME=''
plugins=(git z)

zstyle ':omz:update' frequency 13

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

proxy_on() {
  export http_proxy='http://127.0.0.1:6152'
  export https_proxy='http://127.0.0.1:6152'
  export all_proxy='socks5://127.0.0.1:6153'
  echo 'Proxy enabled'
}

proxy_off() {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  echo 'Proxy disabled'
}

proxy_on_silent() {
  export http_proxy='http://127.0.0.1:6152'
  export https_proxy='http://127.0.0.1:6152'
  export all_proxy='socks5://127.0.0.1:6153'
}

proxy_on_silent

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix)"
else
  HOMEBREW_PREFIX='/opt/homebrew'
fi

[[ -r "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]] && source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
[[ -r "$HOME/.config/alacritty/zsh-alacritty-tmux.zsh" ]] && source "$HOME/.config/alacritty/zsh-alacritty-tmux.zsh"
[[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

alias zshconfig='nvim "$ZDOTDIR/.zshrc"'
alias p10kconfig='nvim "$HOME/.config/alacritty/p10k-alacritty.zsh"'
