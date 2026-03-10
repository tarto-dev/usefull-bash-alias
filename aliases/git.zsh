# ==============================================================================
# Git aliases
# ==============================================================================

alias st='git st'
alias gd='git diff'

# Typo guards
alias gut='git'
alias got='git'

# ------------------------------------------------------------------------------
# Log formats
# ------------------------------------------------------------------------------

# Compact one-liner log (last 10)
alias lc1='git log -n10 --decorate --pretty=format:"%C(cyan)%h%Creset %C(yellow)%an%Creset %C(green)(%ar)%Creset %C(red bold)%d%Creset %s"'

# Log with full commit body
alias lc2='git log -n10 --decorate --pretty=format:"%C(cyan)%h%Creset %C(yellow)%an%Creset %C(green)(%ar)%Creset %C(red bold)%d%Creset%n%B%n%C(240)────────────────────────────%Creset%n"'

# Log with changed files
alias lc3='git log -n10 --decorate --name-status --pretty=format:"%C(cyan)%h%Creset %C(yellow)%an%Creset %C(green)(%ar)%Creset %C(red bold)%d%Creset%n%B"'
