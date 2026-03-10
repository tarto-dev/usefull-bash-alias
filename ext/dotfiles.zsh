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

# ------------------------------------------------------------------------------
# dotfiles-help - List all available functions and aliases
# Usage: dotfiles-help
# ------------------------------------------------------------------------------
dotfiles-help() {
  echo ""
  echo "  dotfiles — available commands"
  echo ""

  # --- Dotfiles management ---
  echo "  ⚙️  dotfiles"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  dotfiles-help                     This help"
  echo "  dotfiles-check                    Check required tools"
  echo "  dotfiles-install-requirements     Install missing tools"
  echo "  dotfiles-update                   Pull latest + reload shell"
  echo ""

  # --- Git functions ---
  echo "  🌿 git functions"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  git-nb <branch>                   Create and push new branch"
  echo "  git-eb <branch>                   Checkout remote branch locally"
  echo "  git-rmc <branch> <commit>         Remove a pushed commit"
  echo "  git-cleaner                       Delete merged local branches"
  echo "  git-merged <commit>               Check which branches contain a commit"
  echo "  mdiff <branch> [file] [opts]      Diff branch vs master"
  echo "  compare <branch>                  Stat diff branch vs master"
  echo "  up                                git pull all repos recursively"
  echo "  lc-release <target>               Changelog from master to branch"
  echo "  lc-release <source> <dest>        Changelog between two refs"
  echo "  smart-commit [-s] [context]       AI-powered atomic commits"
  echo ""

  # --- Git aliases ---
  echo "  🌿 git aliases"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  st / gut / got                    git status / typo guards"
  echo "  gd                                git diff"
  echo "  lc1 / lc2 / lc3                   Git log formats (compact/body/files)"
  echo "  git lc / lc1 / lc2               Git log formats (via .gitconfig)"
  echo "  git lg / lg1                      Git log graph"
  echo "  git sl / sa / ss                  Stash list / apply / save"
  echo "  git r / r1 / r2                   Reset / reset HEAD^ / HEAD^^"
  echo "  git search <keyword>              Search through all commits"
  echo ""

  # --- Files ---
  echo "  📁 files"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  extract <file>                    Extract any archive format"
  echo "  copyfile <file>                   Copy file contents to clipboard"
  echo "  zero-byte <dir>                   Find all empty files in directory"
  echo ""

  # --- Network ---
  echo "  🌐 network"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  ssl <domain>                      Show full SSL certificate details"
  echo "  ssl-test <domain>                 Show SSL certificate validity dates"
  echo "  isdown <url>                      Check if URL responds (HEAD request)"
  echo ""

  # --- Utils ---
  echo "  🔧 utils"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  genpwd <length>                   Generate random alphanumeric password"
  echo "  grh <pattern>                     Recursive grep from current directory"
  echo "  giveme [user:group]               Recursively chown current directory"
  echo "  say <text>                        Text-to-speech (macOS/Linux)"
  echo ""

  # --- System aliases ---
  echo "  🖥️  system aliases"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  r / reload                        Reload ~/.zshrc"
  echo "  c                                 clear"
  echo "  cat                               bat --style=plain"
  echo "  ls / ll / la                      eza with icons and git status"
  echo "  .. / ... / ....                   Navigate up directories"
  echo "  www                               cd ~/Projects"
  echo "  please                            sudo"
  echo "  ping                              ping -c 5"
  echo "  header / headerc                  curl -I / curl -I --compress"
  echo ""
}
