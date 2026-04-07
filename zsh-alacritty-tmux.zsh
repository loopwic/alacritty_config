# Alacritty + tmux friendly Zsh defaults.
# Source this file from ~/.zshrc:
#   source ~/.config/alacritty/zsh-alacritty-tmux.zsh

# Only run for interactive shells.
[[ -o interactive ]] || return 0

# Keep history in XDG state directory when available.
if [[ -n "${XDG_STATE_HOME:-}" ]]; then
  HISTFILE="$XDG_STATE_HOME/zsh/history"
else
  HISTFILE="$HOME/.local/state/zsh/history"
fi
HISTSIZE=50000
SAVEHIST=50000

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Stable and fast completion cache.
autoload -Uz compinit
if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
  _zcompdump_path="$XDG_CACHE_HOME/zsh/zcompdump"
else
  _zcompdump_path="$HOME/.cache/zsh/zcompdump"
fi
mkdir -p "${_zcompdump_path:h}"
compinit -d "$_zcompdump_path"
unset _zcompdump_path

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Line editing behavior aligned with Alacritty key mappings.
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[^?' backward-kill-word

# Better defaults.
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS

# Tools.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi
export VISUAL="$EDITOR"

# tmux helpers.
alias ta='tmux new-session -A -s main'
alias tls='tmux list-sessions'
alias tk='tmux kill-session -t'

# Lightweight git-aware prompt without external frameworks.
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{6}(%b)%f'

precmd() {
  vcs_info
}

PROMPT='%F{3}%n%f@%F{2}%m%f %F{4}%~%f ${vcs_info_msg_0_} %# '
