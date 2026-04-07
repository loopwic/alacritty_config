# Alacritty + tmux friendly Zsh defaults.
# Source this file from ~/.zshrc:
#   source ~/.config/alacritty/zsh-alacritty-tmux.zsh

# Only run for interactive shells.
[[ -o interactive ]] || return 0

# Keep history in a stable local path.
HISTFILE="$HOME/.local/state/zsh/history"
mkdir -p "${HISTFILE:h}"
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

# tmux helpers.
alias ta='tmux new-session -A -s main'
alias tls='tmux list-sessions'
alias tk='tmux kill-session -t'
