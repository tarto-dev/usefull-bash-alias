# ==============================================================================
# File functions
# ==============================================================================

# ------------------------------------------------------------------------------
# extract - Extract any archive based on its extension
# Usage: extract <file>
# ------------------------------------------------------------------------------
extract() {
    if [[ -z "$1" ]]; then
        echo "Usage: extract <file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "'$1' is not a valid file"
        return 1
    fi

    case "$1" in
        *.tar.bz2)  tar xjf "$1"    ;;
        *.tar.gz)   tar xzf "$1"    ;;
        *.tar.xz)   tar xJf "$1"    ;;
        *.bz2)      bunzip2 "$1"    ;;
        *.rar)      unrar e "$1"    ;;
        *.gz)       gunzip "$1"     ;;
        *.tar)      tar xf "$1"     ;;
        *.tbz2)     tar xjf "$1"    ;;
        *.tgz)      tar xzf "$1"    ;;
        *.zip)      unzip "$1"      ;;
        *.Z)        uncompress "$1" ;;
        *.7z)       7z x "$1"       ;;
        *)          echo "'$1' cannot be extracted via extract()" ;;
    esac
}

# ------------------------------------------------------------------------------
# copyfile - Copy file contents to clipboard
# Usage: copyfile <file>
# Supports: macOS (pbcopy), Linux (xclip, xsel)
# Returns: 1 if no clipboard tool found
# ------------------------------------------------------------------------------
copyfile() {
    if [[ -z "$1" ]]; then
        echo "Usage: copyfile <file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a file or does not exist"
        return 1
    fi

    if command -v pbcopy &>/dev/null; then
        cat "$1" | pbcopy
    elif command -v xclip &>/dev/null; then
        cat "$1" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        cat "$1" | xsel --clipboard --input
    else
        echo "Error: no clipboard tool found (pbcopy / xclip / xsel)"
        return 1
    fi

    echo "Copied '$1' to clipboard"
}

# ------------------------------------------------------------------------------
# zero-byte - Find all zero-byte files in a directory
# Usage: zero-byte <directory>
# ------------------------------------------------------------------------------
zero-byte() {
    if [[ -z "$1" ]]; then
        echo "Usage: zero-byte <directory>"
        return 1
    fi
    find "$1" -size 0 -print
}
