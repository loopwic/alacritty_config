# Alacritty-scoped login shell environment.

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export LANG="${LANG:-zh_CN.UTF-8}"
export LC_ALL="${LC_ALL:-zh_CN.UTF-8}"
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"

[[ -r "$HOME/.profile" ]] && source "$HOME/.profile"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

typeset -U path PATH
path=(
  /opt/homebrew/opt/make/libexec/gnubin
  /opt/homebrew/opt/ruby/bin
  /opt/homebrew/lib/ruby/gems/3.4.0/bin
  /opt/homebrew/opt/openjdk@21/bin
  /opt/nanobrew/prefix/bin
  "$HOME/.bun/bin"
  "$HOME/.local/bin"
  $path
)
export PATH
