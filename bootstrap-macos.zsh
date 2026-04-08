#!/usr/bin/env zsh
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "bootstrap-macos.zsh only supports macOS." >&2
  exit 1
fi

SCRIPT_DIR="${0:A:h}"
TARGET_ALACRITTY_DIR="${TARGET_ALACRITTY_DIR:-$HOME/.config/alacritty}"
TARGET_ZSHRC="${TARGET_ZSHRC:-$HOME/.zshrc}"
TARGET_ZPROFILE="${TARGET_ZPROFILE:-$HOME/.zprofile}"
TARGET_ZSHENV="${TARGET_ZSHENV:-$HOME/.zshenv}"
TARGET_TMUX_CONF="${TARGET_TMUX_CONF:-$HOME/.tmux.conf}"
TARGET_P10K="${TARGET_P10K:-$HOME/.p10k.zsh}"

ZSHRC_BEGIN="# >>> alacritty-bootstrap-zshrc >>>"
ZSHRC_END="# <<< alacritty-bootstrap-zshrc <<<"
ZPROFILE_BEGIN="# >>> alacritty-bootstrap-zprofile >>>"
ZPROFILE_END="# <<< alacritty-bootstrap-zprofile <<<"
LEGACY_ZSH_BEGIN="# >>> alacritty-zsh-managed >>>"
LEGACY_ZSH_END="# <<< alacritty-zsh-managed <<<"
LEGACY_ZPROFILE_BEGIN="# >>> alacritty-zprofile-mise-managed >>>"
LEGACY_ZPROFILE_END="# <<< alacritty-zprofile-mise-managed <<<"

CLEAN_EXISTING=1
BREW_UPDATE=1
DRY_RUN=0

typeset -a REQUESTED_TOOLS
REQUESTED_TOOLS=()

usage() {
  cat <<'EOF'
Usage:
  zsh ~/.config/alacritty/bootstrap-macos.zsh [options] [tool@version ...]

Options:
  --dry-run         Print actions without mutating the machine
  --no-cleanup      Keep existing runtime managers and shell hooks
  --no-brew-update  Skip `brew update`
  -h, --help        Show this help

Default mise-managed toolchains:
  node@24 python@latest ruby@latest go@1 java@openjdk-21 rust@stable

Examples:
  zsh ~/.config/alacritty/bootstrap-macos.zsh
  zsh ~/.config/alacritty/bootstrap-macos.zsh node@24 python@3.13 java@openjdk-21
  zsh ~/.config/alacritty/bootstrap-macos.zsh --dry-run
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --no-cleanup)
      CLEAN_EXISTING=0
      ;;
    --no-brew-update)
      BREW_UPDATE=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      REQUESTED_TOOLS+=("$1")
      ;;
  esac
  shift
done

if (( ${#REQUESTED_TOOLS[@]} == 0 )); then
  REQUESTED_TOOLS=(
    "${MISE_NODE_SPEC:-node@24}"
    "${MISE_PYTHON_SPEC:-python@latest}"
    "${MISE_RUBY_SPEC:-ruby@latest}"
    "${MISE_GO_SPEC:-go@1}"
    "${MISE_JAVA_SPEC:-java@openjdk-21}"
    "${MISE_RUST_SPEC:-rust@stable}"
  )
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${BOOTSTRAP_BACKUP_ROOT:-$HOME/.local/state/alacritty-bootstrap/backups/$TIMESTAMP}"

if (( ! DRY_RUN )); then
  mkdir -p "$BACKUP_ROOT"
fi

BREW_BIN=""
MISE_BIN=""

log() {
  printf '[bootstrap] %s\n' "$*"
}

warn() {
  printf '[bootstrap][warn] %s\n' "$*" >&2
}

run() {
  if (( DRY_RUN )); then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

find_brew_bin() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  return 1
}

refresh_tool_paths() {
  BREW_BIN="$(find_brew_bin || true)"
  if [[ -n "$BREW_BIN" ]]; then
    export HOMEBREW_PREFIX="$("$BREW_BIN" --prefix)"
    if (( ! DRY_RUN )); then
      eval "$("$BREW_BIN" shellenv)"
    fi
  fi
  if command -v mise >/dev/null 2>&1; then
    MISE_BIN="$(command -v mise)"
  elif [[ -n "$BREW_BIN" && -x "${HOMEBREW_PREFIX}/bin/mise" ]]; then
    MISE_BIN="${HOMEBREW_PREFIX}/bin/mise"
  else
    MISE_BIN=""
  fi
}

backup_file_if_exists() {
  local file_path="$1"
  local target

  if [[ ! -e "$file_path" ]]; then
    return 0
  fi

  target="$BACKUP_ROOT/files/${file_path:t}"
  if [[ -e "$target" ]]; then
    target="$BACKUP_ROOT/files/${file_path:t}.${RANDOM}"
  fi

  if (( DRY_RUN )); then
    log "Would back up $file_path -> $target"
    return 0
  fi

  mkdir -p "${target:h}"
  cp -p "$file_path" "$target"
}

quarantine_path_if_exists() {
  local item_path="$1"
  local target

  if [[ ! -e "$item_path" ]]; then
    return 0
  fi

  target="$BACKUP_ROOT/quarantine/${item_path:t}"
  if [[ -e "$target" ]]; then
    target="$BACKUP_ROOT/quarantine/${item_path:t}.${RANDOM}"
  fi

  if (( DRY_RUN )); then
    log "Would move $item_path -> $target"
    return 0
  fi

  mkdir -p "${target:h}"
  mv "$item_path" "$target"
}

copy_asset() {
  local source="$1"
  local destination="$2"
  local mode="${3:-}"

  if [[ ! -f "$source" ]]; then
    warn "Skipping missing asset: $source"
    return 0
  fi

  if [[ "${source:A}" == "${destination:A}" ]]; then
    return 0
  fi

  run mkdir -p "${destination:h}"
  run cp "$source" "$destination"

  if [[ -n "$mode" ]]; then
    run chmod "$mode" "$destination"
  fi
}

ensure_homebrew() {
  refresh_tool_paths
  if [[ -n "$BREW_BIN" ]]; then
    return 0
  fi

  log "Installing Homebrew"
  if (( DRY_RUN )); then
    log "Would install Homebrew from the official installer"
    if [[ "$(uname -m)" == "arm64" ]]; then
      BREW_BIN="/opt/homebrew/bin/brew"
      export HOMEBREW_PREFIX="/opt/homebrew"
    else
      BREW_BIN="/usr/local/bin/brew"
      export HOMEBREW_PREFIX="/usr/local"
    fi
    return 0
  fi

  local installer
  installer="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  NONINTERACTIVE=1 /bin/bash "$installer"
  rm -f "$installer"

  refresh_tool_paths

  if [[ -z "$BREW_BIN" ]]; then
    echo "Homebrew installation succeeded but brew was not found in the expected paths." >&2
    exit 1
  fi
}

ensure_brew_packages() {
  log "Installing Homebrew dependencies"

  if (( BREW_UPDATE )); then
    run "$BREW_BIN" update
  fi

  run "$BREW_BIN" install mise tmux powerlevel10k
  run "$BREW_BIN" install --cask font-fira-code-nerd-font
  run "$BREW_BIN" install --cask alacritty

  refresh_tool_paths
}

cleanup_brew_runtime_formulas() {
  local formula cask
  local -A leaf_formula=()

  if (( DRY_RUN )); then
    log "Would inspect Homebrew for conflicting runtime formulae and casks"
    return 0
  fi

  while IFS= read -r formula; do
    [[ -n "$formula" ]] && leaf_formula["$formula"]=1
  done < <("$BREW_BIN" leaves)

  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    case "$formula" in
      node|node@*|python|python@*|ruby|ruby@*|go|go@*|openjdk|openjdk@*|rust|rustup|rustup-init)
        if [[ -n "${leaf_formula[$formula]-}" ]]; then
          log "Uninstalling conflicting Homebrew formula: $formula"
          "$BREW_BIN" uninstall --formula --force "$formula"
        else
          warn "Keeping $formula because other Homebrew packages depend on it; unlinking instead."
          "$BREW_BIN" unlink "$formula" || true
        fi
        ;;
    esac
  done < <("$BREW_BIN" list --formula)

  while IFS= read -r cask; do
    [[ -n "$cask" ]] || continue
    case "$cask" in
      temurin|temurin@*|zulu|zulu@*|corretto|corretto@*|graalvm-jdk|oracle-jdk|oracle-java)
        log "Uninstalling conflicting Java cask: $cask"
        "$BREW_BIN" uninstall --cask --force "$cask"
        ;;
    esac
  done < <("$BREW_BIN" list --cask)
}

cleanup_non_mise_runtime_managers() {
  local item_path
  typeset -a paths

  paths=(
    "$HOME/.nvm"
    "$HOME/.nodenv"
    "$HOME/.volta"
    "$HOME/.fnm"
    "$HOME/.pyenv"
    "$HOME/.rbenv"
    "$HOME/.goenv"
    "$HOME/.gvm"
    "$HOME/.jenv"
    "$HOME/.jabba"
    "$HOME/.cargo"
    "$HOME/.rustup"
    "$HOME/.sdkman/candidates/java"
    "$HOME/.asdf/installs/nodejs"
    "$HOME/.asdf/installs/python"
    "$HOME/.asdf/installs/ruby"
    "$HOME/.asdf/installs/golang"
    "$HOME/.asdf/installs/java"
    "$HOME/.asdf/installs/rust"
    "$HOME/.asdf/downloads/nodejs"
    "$HOME/.asdf/downloads/python"
    "$HOME/.asdf/downloads/ruby"
    "$HOME/.asdf/downloads/golang"
    "$HOME/.asdf/downloads/java"
    "$HOME/.asdf/downloads/rust"
    "$HOME/.asdf/plugins/nodejs"
    "$HOME/.asdf/plugins/python"
    "$HOME/.asdf/plugins/ruby"
    "$HOME/.asdf/plugins/golang"
    "$HOME/.asdf/plugins/java"
    "$HOME/.asdf/plugins/rust"
  )

  for item_path in "${paths[@]}"; do
    quarantine_path_if_exists "$item_path"
  done
}

scrub_shell_file() {
  local file="$1"
  local tmp
  local legacy_regex='(NVM_DIR|nvm\.sh|\.nvm|nodenv|\.nodenv|pyenv|\.pyenv|rbenv|\.rbenv|goenv|\.goenv|gvm|\.gvm|jenv|\.jenv|sdkman-init\.sh|\.sdkman/candidates/java|jabba|\.jabba|volta|\.volta|fnm|\.fnm|asdf\.sh|\.asdf/(installs|downloads|plugins)|\.cargo/bin|cargo/env|rustup|rtx activate|mise activate zsh|p10k-instant-prompt|POWERLEVEL9K_INSTANT_PROMPT|\$ZSH/oh-my-zsh\.sh|/oh-my-zsh\.sh)'

  if [[ ! -f "$file" ]]; then
    if (( DRY_RUN )); then
      log "Would create $file"
    else
      : > "$file"
    fi
  fi

  backup_file_if_exists "$file"

  if (( DRY_RUN )); then
    log "Would scrub legacy runtime hooks from $file"
    return 0
  fi

  tmp="$(mktemp)"
  awk \
    -v zsh_begin="$ZSHRC_BEGIN" \
    -v zsh_end="$ZSHRC_END" \
    -v zprofile_begin="$ZPROFILE_BEGIN" \
    -v zprofile_end="$ZPROFILE_END" \
    -v legacy_begin="$LEGACY_ZSH_BEGIN" \
    -v legacy_end="$LEGACY_ZSH_END" \
    -v legacy_profile_begin="$LEGACY_ZPROFILE_BEGIN" \
    -v legacy_profile_end="$LEGACY_ZPROFILE_END" \
    -v legacy_regex="$legacy_regex" '
      $0 == zsh_begin { skip = 1; next }
      $0 == zsh_end { skip = 0; next }
      $0 == zprofile_begin { skip = 1; next }
      $0 == zprofile_end { skip = 0; next }
      $0 == legacy_begin { skip = 1; next }
      $0 == legacy_end { skip = 0; next }
      $0 == legacy_profile_begin { skip = 1; next }
      $0 == legacy_profile_end { skip = 0; next }
      skip { next }
      $0 ~ legacy_regex { next }
      { print }
    ' "$file" > "$tmp"

  mv "$tmp" "$file"
}

write_zprofile_block() {
  if (( DRY_RUN )); then
    log "Would append managed mise shim block to $TARGET_ZPROFILE"
    return 0
  fi

  [[ -f "$TARGET_ZPROFILE" ]] || : > "$TARGET_ZPROFILE"

  cat >> "$TARGET_ZPROFILE" <<'EOF'

# >>> alacritty-bootstrap-zprofile >>>
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi
# <<< alacritty-bootstrap-zprofile <<<
EOF
}

write_zshrc_block() {
  if (( DRY_RUN )); then
    log "Would append managed shell block to $TARGET_ZSHRC"
    return 0
  fi

  [[ -f "$TARGET_ZSHRC" ]] || : > "$TARGET_ZSHRC"

  cat >> "$TARGET_ZSHRC" <<'EOF'

# >>> alacritty-bootstrap-zshrc >>>
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
  fi
fi

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
[[ -r "$HOME/.config/alacritty/zsh-alacritty-tmux.zsh" ]] && source "$HOME/.config/alacritty/zsh-alacritty-tmux.zsh"
# <<< alacritty-bootstrap-zshrc <<<
EOF
}

sync_alacritty_assets() {
  log "Syncing Alacritty assets into $TARGET_ALACRITTY_DIR"

  run mkdir -p "$TARGET_ALACRITTY_DIR"

  copy_asset "$SCRIPT_DIR/alacritty.toml" "$TARGET_ALACRITTY_DIR/alacritty.toml"
  copy_asset "$SCRIPT_DIR/rose-pine.toml" "$TARGET_ALACRITTY_DIR/rose-pine.toml"
  copy_asset "$SCRIPT_DIR/rose-pine-moon.toml" "$TARGET_ALACRITTY_DIR/rose-pine-moon.toml"
  copy_asset "$SCRIPT_DIR/rose-pine-dawn.toml" "$TARGET_ALACRITTY_DIR/rose-pine-dawn.toml"
  copy_asset "$SCRIPT_DIR/catppuccin-latte.toml" "$TARGET_ALACRITTY_DIR/catppuccin-latte.toml"
  copy_asset "$SCRIPT_DIR/catppuccin-frappe.toml" "$TARGET_ALACRITTY_DIR/catppuccin-frappe.toml"
  copy_asset "$SCRIPT_DIR/catppuccin-macchiato.toml" "$TARGET_ALACRITTY_DIR/catppuccin-macchiato.toml"
  copy_asset "$SCRIPT_DIR/catppuccin-mocha.toml" "$TARGET_ALACRITTY_DIR/catppuccin-mocha.toml"
  copy_asset "$SCRIPT_DIR/zsh-alacritty-tmux.zsh" "$TARGET_ALACRITTY_DIR/zsh-alacritty-tmux.zsh" 755
  copy_asset "$SCRIPT_DIR/apply-zsh-optimizations.zsh" "$TARGET_ALACRITTY_DIR/apply-zsh-optimizations.zsh" 755
  copy_asset "$SCRIPT_DIR/bootstrap-macos.zsh" "$TARGET_ALACRITTY_DIR/bootstrap-macos.zsh" 755
  copy_asset "$SCRIPT_DIR/tmux.conf" "$TARGET_ALACRITTY_DIR/tmux.conf"
  copy_asset "$SCRIPT_DIR/p10k-alacritty.zsh" "$TARGET_ALACRITTY_DIR/p10k-alacritty.zsh"
  copy_asset "$SCRIPT_DIR/README.md" "$TARGET_ALACRITTY_DIR/README.md"
}

install_shell_configs() {
  log "Installing zsh / tmux / powerlevel10k configuration"

  backup_file_if_exists "$TARGET_TMUX_CONF"
  backup_file_if_exists "$TARGET_P10K"

  copy_asset "$SCRIPT_DIR/tmux.conf" "$TARGET_TMUX_CONF"
  copy_asset "$SCRIPT_DIR/p10k-alacritty.zsh" "$TARGET_P10K"

  scrub_shell_file "$TARGET_ZSHRC"
  scrub_shell_file "$TARGET_ZPROFILE"
  scrub_shell_file "$TARGET_ZSHENV"

  write_zprofile_block
  write_zshrc_block
}

install_mise_toolchains() {
  if [[ -z "$MISE_BIN" ]]; then
    echo "mise was not found after Homebrew installation." >&2
    exit 1
  fi

  log "Installing mise-managed toolchains: ${REQUESTED_TOOLS[*]}"
  run "$MISE_BIN" use --global --yes "${REQUESTED_TOOLS[@]}"
}

print_summary() {
  printf '\n'
  log "Done"
  printf '  Alacritty config: %s\n' "$TARGET_ALACRITTY_DIR"
  printf '  zshrc:            %s\n' "$TARGET_ZSHRC"
  printf '  zprofile:         %s\n' "$TARGET_ZPROFILE"
  printf '  zshenv:           %s\n' "$TARGET_ZSHENV"
  printf '  tmux.conf:        %s\n' "$TARGET_TMUX_CONF"
  printf '  p10k config:      %s\n' "$TARGET_P10K"
  printf '  mise toolchains:  %s\n' "${REQUESTED_TOOLS[*]}"
  printf '  backup root:      %s\n' "$BACKUP_ROOT"
  printf '\n'
  printf 'Next steps:\n'
  printf '  1. Restart Alacritty or run: source %q && exec zsh -l\n' "$TARGET_ZSHRC"
  printf '  2. Verify runtimes: node -v && python3 --version && ruby -v && go version && java -version && rustc -V\n'
  printf '  3. Verify tmux: tmux start-server && tmux show -gv default-shell\n'
}

main() {
  log "Preparing macOS bootstrap"
  ensure_homebrew
  ensure_brew_packages
  sync_alacritty_assets

  if (( CLEAN_EXISTING )); then
    log "Cleaning conflicting runtime installations before switching to mise"
    cleanup_brew_runtime_formulas
    cleanup_non_mise_runtime_managers
  else
    warn "Skipping cleanup of pre-existing runtime managers"
  fi

  install_shell_configs
  install_mise_toolchains
  print_summary
}

main "$@"
