#!/usr/bin/env bash
# ==============================================================================
# install.sh — Dotfiles installer (macOS + Linux)
# https://github.com/tarto-dev/usefull-bash-alias
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------
REPO_URL="https://github.com/tarto-dev/usefull-bash-alias.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET} $*"; }
success() { echo -e "${GREEN}[ok]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET} $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; }

OS="$(uname)"

# ------------------------------------------------------------------------------
# Detect package manager
# ------------------------------------------------------------------------------
install_pkg() {
  if [[ "$OS" == "Darwin" ]]; then
    brew install "$@"
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$@"
  else
    warn "Package manager not found — install manually: $*"
  fi
}

# ------------------------------------------------------------------------------
# Homebrew (macOS)
# ------------------------------------------------------------------------------
install_homebrew() {
  if [[ "$OS" != "Darwin" ]]; then return; fi
  if command -v brew &>/dev/null; then
    success "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# ------------------------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------------------------
install_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    success "Oh My Zsh already installed"
    return
  fi
  info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# ------------------------------------------------------------------------------
# Powerlevel10k
# ------------------------------------------------------------------------------
install_p10k() {
  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$p10k_dir" ]]; then
    success "Powerlevel10k already installed"
    return
  fi
  info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
}

# ------------------------------------------------------------------------------
# OMZ plugins
# ------------------------------------------------------------------------------
install_omz_plugins() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

  declare -A PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
    [zsh-history-enquirer]="https://github.com/zthxxx/zsh-history-enquirer"
  )

  for plugin in "${!PLUGINS[@]}"; do
    if [[ -d "$custom/$plugin" ]]; then
      success "Plugin $plugin already installed"
    else
      info "Installing plugin $plugin..."
      git clone --depth=1 "${PLUGINS[$plugin]}" "$custom/$plugin"
    fi
  done
}

# ------------------------------------------------------------------------------
# CLI tools
# ------------------------------------------------------------------------------
install_tools() {
  info "Installing CLI tools..."

  local tools_common=(git bat eza fzf zoxide fortune)
  local tools_macos=(ponysay lolcat thefuck)
  local tools_linux=(ponysay lolcat thefuck)

  for tool in "${tools_common[@]}"; do
    if command -v "$tool" &>/dev/null; then
      success "$tool already installed"
    else
      info "Installing $tool..."
      install_pkg "$tool"
    fi
  done

  if [[ "$OS" == "Darwin" ]]; then
    for tool in "${tools_macos[@]}"; do
      if command -v "$tool" &>/dev/null; then
        success "$tool already installed"
      else
        info "Installing $tool..."
        install_pkg "$tool"
      fi
    done
  else
    for tool in "${tools_linux[@]}"; do
      if command -v "$tool" &>/dev/null; then
        success "$tool already installed"
      else
        info "Installing $tool..."
        install_pkg "$tool" 2>/dev/null || warn "$tool not available via package manager, skip"
      fi
    done

    # xclip fallback clipboard
    if ! command -v xclip &>/dev/null && ! command -v xsel &>/dev/null; then
      info "Installing xclip..."
      install_pkg xclip
    fi
  fi
}

# ------------------------------------------------------------------------------
# Kaamelott fortunes
# ------------------------------------------------------------------------------
install_fortunes() {
  local fortune_dir="$HOME/.local/share/fortunes-kaamelott"
  if [[ -d "$fortune_dir" ]]; then
    success "Kaamelott fortunes already installed"
    return
  fi
  info "Installing Kaamelott fortunes..."
  mkdir -p "$(dirname "$fortune_dir")"
  git clone https://github.com/methatronc/fortunes-kaamelott "$fortune_dir"
  if command -v strfile &>/dev/null; then
    strfile "$fortune_dir/fortunes-kaamelott" 2>/dev/null || true
  else
    warn "strfile not found — run manually: strfile $fortune_dir/fortunes-kaamelott"
  fi
}

# ------------------------------------------------------------------------------
# Clone / update dotfiles repo
# ------------------------------------------------------------------------------
setup_dotfiles_repo() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    info "Dotfiles repo already cloned, pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only
  else
    info "Cloning dotfiles repo to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
  fi
}

# ------------------------------------------------------------------------------
# Backup existing files
# ------------------------------------------------------------------------------
backup_existing() {
  local files=(
    "$HOME/.zshrc"
    "$HOME/.bash_aliases"
    "$HOME/.bash_functions"
    "$HOME/.gitconfig"
  )
  local backed_up=false

  for f in "${files[@]}"; do
    if [[ -f "$f" && ! -L "$f" ]]; then
      if [[ "$backed_up" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        backed_up=true
        warn "Backing up existing files to $BACKUP_DIR"
      fi
      cp "$f" "$BACKUP_DIR/"
      success "Backed up $f"
    fi
  done
}

# ------------------------------------------------------------------------------
# Symlinks
# ------------------------------------------------------------------------------
link_dotfiles() {
  info "Creating symlinks..."

  ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  success "Linked .zshrc"

  ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  success "Linked .gitconfig"

  # gitconfig.local: overrides locaux non versionnés (email perso, signing key...)
  if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    cat > "$HOME/.gitconfig.local" << 'EOF'
# Local git overrides — not versioned
# Uncomment and fill to override .gitconfig values
# [user]
# 	email = perso@example.com
# 	name = Clara Cassinat
EOF
    warn ".gitconfig.local created — fill it in for machine-specific overrides"
  fi

  # SSH aliases: create local file if not exists (gitignored)
  if [[ ! -f "$DOTFILES_DIR/ssh/aliases.zsh" ]]; then
    touch "$DOTFILES_DIR/ssh/aliases.zsh"
    warn "ssh/aliases.zsh created — add your SSH aliases there (not versioned)"
  fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║        dotfiles installer            ║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${RESET}"
  echo ""

  install_homebrew
  install_ohmyzsh
  install_p10k
  install_omz_plugins
  install_tools
  install_fortunes
  setup_dotfiles_repo
  backup_existing
  link_dotfiles

  echo ""
  success "Installation complete!"
  echo ""
  info "Next steps:"
  echo "  1. Add your SSH aliases to ~/.dotfiles/ssh/aliases.zsh"
  echo "  2. Edit ~/.gitconfig.local for machine-specific git config (email, signing key...)"
  echo "  3. Run: source ~/.zshrc"
  echo "  4. Run p10k configure if needed"
  echo ""
}

main "$@"
