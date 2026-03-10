# ==============================================================================
# Linux-only aliases — guarded, not sourced on macOS
# ==============================================================================

[[ "$(uname)" != "Linux" ]] && return 0

# ------------------------------------------------------------------------------
# System info
# ------------------------------------------------------------------------------
alias cpuinfo='lscpu'
alias meminfo='free -m -l -t'
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

# ------------------------------------------------------------------------------
# Process
# ------------------------------------------------------------------------------
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
