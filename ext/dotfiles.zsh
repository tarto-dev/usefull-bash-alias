# ==============================================================================
# dotfiles — Management functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Requirements definition
# ------------------------------------------------------------------------------
# Format: "command|package_name_macos|package_name_linux|description"
# package_name_* = nom brew / apt pour install automatique
# Si le package = "manual", on affiche juste un warning sans tenter d'installer
_DOTFILES_REQUIREMENTS=(
  "git|git|git|Version control"
  "zsh|zsh|zsh|Shell"
  "bat|bat|bat|Modern cat replacement"
  "eza|eza|eza|Modern ls replacement"
  "fzf|fzf|fzf|Fuzzy finder"
  "zoxide|zoxide|zoxide|Smart cd replacement"
  "thefuck|thefuck|thefuck|Command correction"
  "fortune|fortune|fortune|Fortune cookie"
  "ponysay|ponysay|ponysay|Pony ASCII art"
  "lolcat|lolcat|lolcat|Rainbow colorizer"
  "claude|manual|manual|Claude Code CLI (https://claude.ai/code)"
)

# ------------------------------------------------------------------------------
# _dotfiles_os - Detect OS
# ------------------------------------------------------------------------------
_dotfiles_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  else
    echo "linux"
  fi
}

# ------------------------------------------------------------------------------
# _dotfiles_install_pkg - Install a package via the appropriate package manager
# ------------------------------------------------------------------------------
_dotfiles_install_pkg() {
  local pkg="$1"
  if [[ "$pkg" == "manual" ]]; then
    return 1
  fi

  if [[ "$(_dotfiles_os)" == "macos" ]]; then
    brew install "$pkg"
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y "$pkg"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$pkg"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$pkg"
  else
    return 1
  fi
}

# ------------------------------------------------------------------------------
# dotfiles-check - Check all required tools
# Usage: dotfiles-check
# ------------------------------------------------------------------------------
dotfiles-check() {
  local os
  os="$(_dotfiles_os)"
  local missing=0
  local ok=0

  echo ""
  echo "  dotfiles — requirements check"
  echo "  ─────────────────────────────────────────"

  for req in "${_DOTFILES_REQUIREMENTS[@]}"; do
    local cmd pkg_macos pkg_linux desc
    cmd="${req%%|*}"
    rest="${req#*|}"
    pkg_macos="${rest%%|*}"
    rest="${rest#*|}"
    pkg_linux="${rest%%|*}"
    desc="${rest#*|}"

    if command -v "$cmd" &>/dev/null; then
      echo "  ✅ $cmd — $desc"
      (( ok++ ))
    else
      local pkg
      [[ "$os" == "macos" ]] && pkg="$pkg_macos" || pkg="$pkg_linux"
      if [[ "$pkg" == "manual" ]]; then
        echo "  ⚠️  $cmd — $desc (manual install required)"
      else
        echo "  ❌ $cmd — $desc (brew/pkg: $pkg)"
      fi
      (( missing++ ))
    fi
  done

  echo "  ─────────────────────────────────────────"
  echo "  $ok ok, $missing missing"

  if (( missing > 0 )); then
    echo ""
    echo "  Run dotfiles-install-requirements to install missing tools"
  fi
  echo ""
}

# ------------------------------------------------------------------------------
# dotfiles-install-requirements - Install all missing tools
# Usage: dotfiles-install-requirements
# ------------------------------------------------------------------------------
dotfiles-install-requirements() {
  local os
  os="$(_dotfiles_os)"
  local installed=0
  local skipped=0
  local failed=0

  echo ""
  echo "  dotfiles — installing missing requirements"
  echo "  ─────────────────────────────────────────"

  for req in "${_DOTFILES_REQUIREMENTS[@]}"; do
    local cmd pkg_macos pkg_linux desc pkg
    cmd="${req%%|*}"
    rest="${req#*|}"
    pkg_macos="${rest%%|*}"
    rest="${rest#*|}"
    pkg_linux="${rest%%|*}"
    desc="${rest#*|}"

    [[ "$os" == "macos" ]] && pkg="$pkg_macos" || pkg="$pkg_linux"

    if command -v "$cmd" &>/dev/null; then
      echo "  ✅ $cmd already installed, skipping"
      (( skipped++ ))
      continue
    fi

    if [[ "$pkg" == "manual" ]]; then
      echo "  ⚠️  $cmd requires manual install — $desc"
      (( skipped++ ))
      continue
    fi

    echo "  ⬇️  Installing $cmd ($pkg)..."
    if _dotfiles_install_pkg "$pkg"; then
      echo "  ✅ $cmd installed"
      (( installed++ ))
    else
      echo "  ❌ Failed to install $cmd — install manually: $pkg"
      (( failed++ ))
    fi
  done

  echo "  ─────────────────────────────────────────"
  echo "  $installed installed, $skipped skipped, $failed failed"
  echo ""

  if (( installed > 0 )); then
    echo "  Run: source ~/.zshrc to reload"
    echo ""
  fi
}

# ------------------------------------------------------------------------------
# dotfiles-update - Pull latest dotfiles and reload shell
# Usage: dotfiles-update
# ------------------------------------------------------------------------------
dotfiles-update() {
  local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

  if [[ ! -d "$dotfiles_dir/.git" ]]; then
    echo "❌ Dotfiles dir not found: $dotfiles_dir"
    return 1
  fi

  echo "⬇️  Pulling latest dotfiles..."
  git -C "$dotfiles_dir" pull --ff-only || {
    echo "❌ git pull failed — resolve conflicts manually in $dotfiles_dir"
    return 1
  }

  echo "🔄 Reloading shell..."
  source "$HOME/.zshrc"
  echo "✅ Done"
}
