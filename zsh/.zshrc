# ==============================================================================
# Powerlevel10k — instant prompt (must stay at top)
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# Oh My Zsh
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  urltools
  bgnotify
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-enquirer
)

source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# PATH
# ==============================================================================
export PATH="$HOME/.lando/bin:$PATH"
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ==============================================================================
# Environment
# ==============================================================================
export LESS='-R -F -X'
export LESSCHARSET='utf-8'
export HOMEBREW_NO_AUTO_UPDATE=true

# ==============================================================================
# Shell config
# ==============================================================================
source "$HOME/.dotfiles/aliases/system.zsh"
source "$HOME/.dotfiles/aliases/git.zsh"
source "$HOME/.dotfiles/aliases/macos.zsh"   # guarded internally
source "$HOME/.dotfiles/aliases/linux.zsh"   # guarded internally

source "$HOME/.dotfiles/functions/git.zsh"
source "$HOME/.dotfiles/functions/lc-release.zsh"
source "$HOME/.dotfiles/functions/files.zsh"
source "$HOME/.dotfiles/functions/network.zsh"
source "$HOME/.dotfiles/functions/utils.zsh"

source "$HOME/.dotfiles/ext/smart-commit.zsh"
source "$HOME/.dotfiles/ext/dotfiles.zsh"

[[ -f "$HOME/.dotfiles/ssh/aliases.zsh" ]] && source "$HOME/.dotfiles/ssh/aliases.zsh"

# ==============================================================================
# Tools init (order matters)
# ==============================================================================
eval "$(zoxide init zsh)"

# fzf --zsh existe depuis 0.48 — fallback pour les distros avec une version antérieure
if fzf --zsh &>/dev/null 2>&1; then
  eval "$(fzf --zsh)"
elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
elif [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

eval "$(thefuck --alias)"

# ==============================================================================
# Welcome
# ==============================================================================
_dotfiles_welcome() {
  local cols="${COLUMNS:-80}"
  local pad=$(( cols / 4 ))
  fortune ~/.local/share/fortunes-kaamelott/fortunes-kaamelott 2>/dev/null \
    | ponysay 2>/dev/null \
    | sed "s/^/$(printf '%*s' "$pad" '')/"
}
_dotfiles_welcome


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
