#!/usr/bin/env bash
# ==============================================================================
# install.sh — Dotfiles installer (macOS + Linux)
# https://github.com/tarto-dev/usefull-bash-alias
#
# Modes:
#   ./install.sh          Installation complète (fresh ou existant)
#   ./install.sh --update Mise à jour des symlinks uniquement (git pull + relink)
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------
REPO_URL="https://github.com/tarto-dev/usefull-bash-alias.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
MODE="${1:-install}"

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
  [[ "$OS" != "Darwin" ]] && return 0
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
  else
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  # Ensure zsh is the default shell
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -n "$zsh_path" && "$SHELL" != "$zsh_path" ]]; then
    info "Setting zsh as default shell..."
    sudo chsh -s "$zsh_path" "$(whoami)" \
      && success "Default shell set to zsh" \
      || warn "chsh failed — run manually: chsh -s $zsh_path"
  fi
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
# bat — called "batcat" on Debian/Ubuntu (name conflict with another package)
# Creates a "bat" symlink if needed
# ------------------------------------------------------------------------------
install_bat() {
  if command -v bat &>/dev/null; then
    success "bat already installed"
    return
  fi

  if [[ "$OS" == "Darwin" ]]; then
    brew install bat
    return
  fi

  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y bat 2>/dev/null || sudo apt-get install -y batcat
    # On Debian/Ubuntu, binary is "batcat" — create a symlink
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
      success "bat symlinked from batcat → ~/.local/bin/bat"
      warn "Make sure ~/.local/bin is in your PATH (already set in .zshrc)"
    fi
    return
  fi

  install_pkg bat
}

# ------------------------------------------------------------------------------
# eza — not in standard apt repos, requires manual install on Linux
# Sources: GitHub releases (works on all distros)
# ------------------------------------------------------------------------------
install_eza() {
  if command -v eza &>/dev/null; then
    success "eza already installed"
    return
  fi

  if [[ "$OS" == "Darwin" ]]; then
    brew install eza
    return
  fi

  # Linux: try deb repo first (Ubuntu/Debian), fallback to binary from GitHub
  if command -v apt-get &>/dev/null; then
    info "Installing eza via deb repo..."
    if [[ ! -f /etc/apt/keyrings/gierens.gpg ]]; then
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL --max-time 10 https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
      sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    fi
    sudo apt-get update && sudo apt-get install -y eza \
      && success "eza installed via deb repo" && return
  fi

  # Fallback: binary from GitHub releases
  info "Falling back to GitHub binary install for eza..."
  local arch
  arch="$(uname -m)"
  local eza_arch
  case "$arch" in
    x86_64)  eza_arch="x86_64-unknown-linux-gnu" ;;
    aarch64) eza_arch="aarch64-unknown-linux-gnu" ;;
    *)
      warn "eza: unsupported arch $arch — install manually from https://github.com/eza-community/eza/releases"
      return 1
      ;;
  esac

  local tmpdir
  tmpdir="$(mktemp -d)"
  local url="https://github.com/eza-community/eza/releases/latest/download/eza_${eza_arch}.tar.gz"
  wget -qO "$tmpdir/eza.tar.gz" "$url" \
    && tar -xzf "$tmpdir/eza.tar.gz" -C "$tmpdir" \
    && sudo mv "$tmpdir/eza" /usr/local/bin/eza \
    && sudo chmod +x /usr/local/bin/eza \
    && success "eza installed to /usr/local/bin/eza" \
    || warn "eza binary install failed — install manually from https://github.com/eza-community/eza/releases"
  rm -rf "$tmpdir"
}

# ------------------------------------------------------------------------------
# CLI tools
# ------------------------------------------------------------------------------
install_tools() {
  info "Installing CLI tools..."

  # eza et bat ont leur propre fonction (cas particuliers Linux)
  install_bat
  install_eza

  local tools_common=(git fzf zoxide fortune)
  local tools_macos=(ponysay lolcat thefuck)
  local tools_linux=(thefuck)

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
        install_pkg "$tool" 2>/dev/null || warn "$tool not available via package manager — install manually"
      fi
    done

    # ponysay : install from source (https://github.com/erkin/ponysay)
    if ! command -v ponysay &>/dev/null; then
      info "Installing ponysay from source..."
      local tmpdir
      tmpdir="$(mktemp -d)"
      # makeinfo (texinfo) is required by ponysay's setup.py to build info pages
      command -v makeinfo &>/dev/null || install_pkg texinfo
      if git clone --depth=1 https://github.com/erkin/ponysay.git "$tmpdir/ponysay"; then
        cd "$tmpdir/ponysay"
        sudo ./setup.py --prefix=/usr --freedom=partial install \
          && success "ponysay installed" \
          || warn "ponysay install failed — install manually: https://github.com/erkin/ponysay"
        cd - > /dev/null
      else
        warn "ponysay clone failed — install manually: https://github.com/erkin/ponysay"
      fi
      rm -rf "$tmpdir"
    else
      success "ponysay already installed"
    fi

    # lolcat : gem ou pip selon dispo
    if ! command -v lolcat &>/dev/null; then
      if command -v gem &>/dev/null; then
        info "Installing lolcat via gem..."
        gem install lolcat 2>/dev/null || warn "lolcat gem install failed"
      else
        info "Installing lolcat via pip..."
        pip3 install lolcat 2>/dev/null || warn "lolcat install failed — try: gem install lolcat"
      fi
    else
      success "lolcat already installed"
    fi

    # Clipboard fallback
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
    git -C "$DOTFILES_DIR" pull --ff-only || warn "git pull failed — check manually in $DOTFILES_DIR"
  else
    info "Cloning dotfiles repo to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
  fi
}

# ------------------------------------------------------------------------------
# Backup existing files
# Backup uniquement les fichiers réels (pas les symlinks déjà en place)
# ------------------------------------------------------------------------------
backup_existing() {
  # Fichiers à gérer : fichier réel existant OU symlink pointant ailleurs que dotfiles
  local targets=(
    "$HOME/.zshrc:$DOTFILES_DIR/zsh/.zshrc"
    "$HOME/.gitconfig:$DOTFILES_DIR/git/.gitconfig"
    "$HOME/.bash_aliases:"
    "$HOME/.bash_functions:"
    "$HOME/.bash_profile:"
    "$HOME/.bashrc:"
  )

  local backed_up=false

  for entry in "${targets[@]}"; do
    local file="${entry%%:*}"
    local expected_target="${entry##*:}"

    # Fichier n'existe pas du tout → rien à faire
    [[ ! -e "$file" ]] && continue

    # C'est un symlink qui pointe déjà vers notre dotfiles → on le laisse
    if [[ -L "$file" ]]; then
      local current_target
      current_target="$(readlink "$file")"
      if [[ -n "$expected_target" && "$current_target" == "$expected_target" ]]; then
        success "$file already linked to dotfiles, skipping"
        continue
      fi
      # Symlink qui pointe ailleurs → on backup
    fi

    # Fichier réel ou symlink vers autre chose → backup
    if [[ "$backed_up" == false ]]; then
      mkdir -p "$BACKUP_DIR"
      backed_up=true
      warn "Backing up existing files to $BACKUP_DIR"
    fi
    mv "$file" "$BACKUP_DIR/$(basename "$file")"
    success "Backed up $file → $BACKUP_DIR/"
  done

  if [[ "$backed_up" == true ]]; then
    info "Backup complete. To restore: cp $BACKUP_DIR/* ~/"
  fi
}

# ------------------------------------------------------------------------------
# Symlinks
# ------------------------------------------------------------------------------
link_dotfiles() {
  info "Creating symlinks..."

  ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  success "Linked .zshrc → $DOTFILES_DIR/zsh/.zshrc"

  ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  success "Linked .gitconfig → $DOTFILES_DIR/git/.gitconfig"

  # gitconfig.local : overrides locaux non versionnés
  if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    cat > "$HOME/.gitconfig.local" << 'EOF'
# Local git overrides — not versioned
# Uncomment and fill to override .gitconfig values
# [user]
# 	email = perso@example.com
# 	name = Your Name
EOF
    warn ".gitconfig.local created — fill it in for machine-specific overrides"
  else
    success ".gitconfig.local already exists, skipping"
  fi

  # SSH aliases : fichier local gitignored
  if [[ ! -f "$DOTFILES_DIR/ssh/aliases.zsh" ]]; then
    mkdir -p "$DOTFILES_DIR/ssh"
    touch "$DOTFILES_DIR/ssh/aliases.zsh"
    warn "ssh/aliases.zsh created — add your SSH aliases there (not versioned)"
  else
    success "ssh/aliases.zsh already exists, skipping"
  fi
}

# ------------------------------------------------------------------------------
# Mode update : git pull + relink uniquement
# ------------------------------------------------------------------------------
run_update() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║        dotfiles update               ║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${RESET}"
  echo ""

  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    error "Dotfiles not found at $DOTFILES_DIR — run install first"
    exit 1
  fi

  setup_dotfiles_repo
  link_dotfiles

  echo ""
  success "Update complete! Run: source ~/.zshrc"
  echo ""
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
  if [[ "$MODE" == "--update" ]]; then
    run_update
    return
  fi

  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║        dotfiles installer            ║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${RESET}"
  echo ""

  # Détection système existant
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    warn "Existing dotfiles detected at $DOTFILES_DIR"
    info "Running in upgrade mode — tools already installed will be skipped"
  fi

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
  echo "  1. Add your SSH aliases to $DOTFILES_DIR/ssh/aliases.zsh"
  echo "  2. Edit ~/.gitconfig.local for machine-specific git config"
  echo "  3. Run: source ~/.zshrc"
  echo "  4. Run p10k configure if this is a fresh install"
  echo ""
  info "To update dotfiles later: ./install.sh --update"
  echo ""
}

main "$@"
