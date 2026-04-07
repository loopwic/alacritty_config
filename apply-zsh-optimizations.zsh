#!/usr/bin/env zsh
set -euo pipefail

TARGET_ZSHRC="${1:-$HOME/.zshrc}"
BEGIN_MARKER="# >>> alacritty-zsh-managed >>>"
END_MARKER="# <<< alacritty-zsh-managed <<<"

if [[ ! -f "$TARGET_ZSHRC" ]]; then
  touch "$TARGET_ZSHRC"
fi

TMP_FILE="$(mktemp)"

# Remove previously managed block to keep the script idempotent.
awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
  $0 == begin { skip = 1; next }
  $0 == end { skip = 0; next }
  !skip { print }
' "$TARGET_ZSHRC" > "$TMP_FILE"

cat >> "$TMP_FILE" <<'EOF'

# >>> alacritty-zsh-managed >>>
# Deterministic Alacritty + tmux tuning (no fallback)
export EDITOR='nvim'
export VISUAL='nvim'

export NVM_DIR="$HOME/.nvm"
nvm_lazy_load() {
  unset -f nvm node npm npx
  source "/opt/homebrew/opt/nvm/nvm.sh"
  source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}
nvm() { nvm_lazy_load; nvm "$@"; }
node() { nvm_lazy_load; node "$@"; }
npm() { nvm_lazy_load; npm "$@"; }
npx() { nvm_lazy_load; npx "$@"; }

typeset -U path PATH
path=(
  /opt/homebrew/opt/make/libexec/gnubin
  /opt/homebrew/opt/ruby/bin
  /opt/homebrew/lib/ruby/gems/3.4.0/bin
  /opt/homebrew/opt/openjdk@21/bin
  /opt/nanobrew/prefix/bin
  /Users/khm/.bun/bin
  "$HOME/.local/bin"
  $path
)
export PATH

source "$HOME/.config/alacritty/zsh-alacritty-tmux.zsh"
# <<< alacritty-zsh-managed <<<
EOF

mv "$TMP_FILE" "$TARGET_ZSHRC"
echo "Applied deterministic zsh tuning to $TARGET_ZSHRC"
