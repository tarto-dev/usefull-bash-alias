# ==============================================================================
# dotfiles — Management functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Requirements definition
# ------------------------------------------------------------------------------
# Format: "command|package_name_macos|package_name_linux|description"
# Si le package = "manual", on affiche juste un warning sans tenter d'installer
_DOTFILES_REQUIREMENTS=(
  "git|git|git|Version control"
  "zsh|zsh|zsh|Shell"
  "eza|eza|eza|Modern ls replacement"
  "fzf|fzf|fzf|Fuzzy finder"
  "zoxide|zoxide|zoxide|Smart cd replacement"
  "thefuck|thefuck|thefuck|Command correction"
  "fortune|fortune|fortune|Fortune cookie"
  "lolcat|lolcat|lolcat|Rainbow colorizer"
  "lando|manual|manual|Lando (https://lando.dev)"
  "nvm|manual|manual|NVM — check via NVM_DIR"
  "claude|manual|manual|Claude Code CLI (https://claude.ai/code)"
)

# Checks étendus : éléments non détectables via un simple command -v
# Format: "label|check_cmd|description|install_hint"
_DOTFILES_EXTENDED_CHECKS=(
  # bat : s'appelle "batcat" sur Debian/Ubuntu, "bat" ailleurs
  "bat|command -v bat &>/dev/null || command -v batcat &>/dev/null|Modern cat replacement (bat/batcat)|apt install bat  OR  brew install bat"
  # ponysay : installé via pip, pas forcément dans PATH système
  "ponysay|command -v ponysay &>/dev/null || python3 -c 'import ponysay' &>/dev/null 2>&1|Pony ASCII art|pip3 install ponysay"
  "oh-my-zsh|test -d \$HOME/.oh-my-zsh|Oh My Zsh shell framework|https://ohmyz.sh"
  "powerlevel10k|test -d \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k|Powerlevel10k theme|git clone --depth=1 https://github.com/romkatv/powerlevel10k.git"
  "kaamelott-fortunes|test -f \$HOME/.local/share/fortunes-kaamelott/fortunes-kaamelott|Kaamelott fortune cookies|git clone https://github.com/methatronc/fortunes-kaamelott ~/.local/share/fortunes-kaamelott"
  "zsh-autosuggestions|test -d \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions|ZSH autosuggestions plugin|git clone https://github.com/zsh-users/zsh-autosuggestions"
  "zsh-syntax-highlighting|test -d \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting|ZSH syntax highlighting plugin|git clone https://github.com/zsh-users/zsh-syntax-highlighting"
  "zsh-history-enquirer|test -d \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins/zsh-history-enquirer|ZSH history enquirer plugin|git clone https://github.com/zthxxx/zsh-history-enquirer"
  "nvm|test -d \${NVM_DIR:-\$HOME/.nvm}|Node Version Manager|https://github.com/nvm-sh/nvm"
)

# ------------------------------------------------------------------------------
# _dotfiles_os - Detect OS
# ------------------------------------------------------------------------------
_dotfiles_os() {
  [[ "$(uname)" == "Darwin" ]] && echo "macos" || echo "linux"
}

# ------------------------------------------------------------------------------
# _dotfiles_install_pkg - Install a package via the appropriate package manager
# ------------------------------------------------------------------------------
_dotfiles_install_pkg() {
  local pkg="$1"
  [[ "$pkg" == "manual" ]] && return 1

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
  local os missing=0 ok=0
  os="$(_dotfiles_os)"

  echo ""
  echo "  dotfiles — requirements check"
  echo "  ─────────────────────────────────────────"

  for req in "${_DOTFILES_REQUIREMENTS[@]}"; do
    local cmd desc pkg
    cmd="${req%%|*}"
    desc="${req##*|}"
    if [[ "$os" == "macos" ]]; then
      pkg="$(echo "$req" | cut -d'|' -f2)"
    else
      pkg="$(echo "$req" | cut -d'|' -f3)"
    fi

    if command -v "$cmd" &>/dev/null; then
      echo "  ✅ $cmd — $desc"
      (( ok++ ))
    else
      if [[ "$pkg" == "manual" ]]; then
        echo "  ⚠️  $cmd — $desc (manual install required)"
      else
        echo "  ❌ $cmd — $desc (brew/pkg: $pkg)"
      fi
      (( missing++ ))
    fi
  done

  echo ""
  echo "  dotfiles — extended checks"
  echo "  ─────────────────────────────────────────"

  for check in "${_DOTFILES_EXTENDED_CHECKS[@]}"; do
    local label check_cmd desc hint
    label="$(echo "$check" | cut -d'|' -f1)"
    check_cmd="$(echo "$check" | cut -d'|' -f2)"
    desc="$(echo "$check" | cut -d'|' -f3)"
    hint="$(echo "$check" | cut -d'|' -f4)"

    if eval "$check_cmd" 2>/dev/null; then
      echo "  ✅ $label — $desc"
      (( ok++ ))
    else
      echo "  ❌ $label — $desc"
      echo "     → $hint"
      (( missing++ ))
    fi
  done

  echo "  ─────────────────────────────────────────"
  echo "  $ok ok, $missing missing"
  (( missing > 0 )) && echo "\n  Run dotfiles-install-requirements to install missing tools"
  echo ""
}

# ------------------------------------------------------------------------------
# dotfiles-install-requirements - Install all missing tools
# Usage: dotfiles-install-requirements
# ------------------------------------------------------------------------------
dotfiles-install-requirements() {
  local os installed=0 skipped=0 failed=0
  os="$(_dotfiles_os)"

  echo ""
  echo "  dotfiles — installing missing requirements"
  echo "  ─────────────────────────────────────────"

  for req in "${_DOTFILES_REQUIREMENTS[@]}"; do
    local cmd desc pkg
    cmd="${req%%|*}"
    desc="${req##*|}"
    if [[ "$os" == "macos" ]]; then
      pkg="$(echo "$req" | cut -d'|' -f2)"
    else
      pkg="$(echo "$req" | cut -d'|' -f3)"
    fi

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

  echo ""
  echo "  dotfiles — installing extended requirements"
  echo "  ─────────────────────────────────────────"

  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  local -A OMZ_PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
    [zsh-history-enquirer]="https://github.com/zthxxx/zsh-history-enquirer"
  )

  for plugin in "${!OMZ_PLUGINS[@]}"; do
    if [[ -d "$custom/plugins/$plugin" ]]; then
      echo "  ✅ $plugin already installed, skipping"
      (( skipped++ ))
    else
      echo "  ⬇️  Installing $plugin..."
      if git clone --depth=1 "${OMZ_PLUGINS[$plugin]}" "$custom/plugins/$plugin"; then
        echo "  ✅ $plugin installed"
        (( installed++ ))
      else
        echo "  ❌ Failed to install $plugin"
        (( failed++ ))
      fi
    fi
  done

  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$p10k_dir" ]]; then
    echo "  ✅ powerlevel10k already installed, skipping"
    (( skipped++ ))
  else
    echo "  ⬇️  Installing powerlevel10k..."
    if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"; then
      echo "  ✅ powerlevel10k installed"
      (( installed++ ))
    else
      echo "  ❌ Failed to install powerlevel10k"
      (( failed++ ))
    fi
  fi

  local fortune_dir="$HOME/.local/share/fortunes-kaamelott"
  if [[ -f "$fortune_dir/fortunes-kaamelott" ]]; then
    echo "  ✅ kaamelott-fortunes already installed, skipping"
    (( skipped++ ))
  else
    echo "  ⬇️  Installing kaamelott fortunes..."
    mkdir -p "$(dirname "$fortune_dir")"
    if git clone https://github.com/methatronc/fortunes-kaamelott "$fortune_dir"; then
      strfile "$fortune_dir/fortunes-kaamelott" 2>/dev/null || true
      echo "  ✅ kaamelott-fortunes installed"
      (( installed++ ))
    else
      echo "  ❌ Failed to install kaamelott-fortunes"
      (( failed++ ))
    fi
  fi

  echo "  ─────────────────────────────────────────"
  echo "  $installed installed, $skipped skipped, $failed failed"
  (( installed > 0 )) && echo "\n  Run: source ~/.zshrc to reload"
  echo ""
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

  echo "  ⚙️  dotfiles"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  dotfiles-help                     This help"
  echo "  dotfiles-check                    Check required tools"
  echo "  dotfiles-install-requirements     Install missing tools"
  echo "  dotfiles-update                   Pull latest + reload shell"
  echo ""

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

  echo "  📁 files"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  extract <file>                    Extract any archive format"
  echo "  copyfile <file>                   Copy file contents to clipboard"
  echo "  zero-byte <dir>                   Find all empty files in directory"
  echo ""

  echo "  🌐 network"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  ssl <domain>                      Show full SSL certificate details"
  echo "  ssl-test <domain>                 Show SSL certificate validity dates"
  echo "  isdown <url>                      Check if URL responds (HEAD request)"
  echo ""

  echo "  🔧 utils"
  echo "  ─────────────────────────────────────────────────────────"
  echo "  genpwd <length>                   Generate random alphanumeric password"
  echo "  grh <pattern>                     Recursive grep from current directory"
  echo "  giveme [user:group]               Recursively chown current directory"
  echo "  say <text>                        Text-to-speech (macOS/Linux)"
  echo ""

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
