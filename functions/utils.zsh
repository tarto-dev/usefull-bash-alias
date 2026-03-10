# ==============================================================================
# Utility functions
# ==============================================================================

# ------------------------------------------------------------------------------
# genpwd - Generate a random alphanumeric password
# Usage: genpwd <length>
# Example: genpwd 16
# ------------------------------------------------------------------------------
genpwd() {
    if [[ -z "$1" ]]; then
        echo "Usage: genpwd <length>"
        return 1
    fi
    strings /dev/urandom | grep -o '[[:alnum:]]' | head -n "$1" | tr -d '\n'
    echo
}

# ------------------------------------------------------------------------------
# grh - Recursive grep from current directory
# Usage: grh <pattern>
# Example: grh "function myFunc"
# ------------------------------------------------------------------------------
grh() {
    if [[ -z "$1" ]]; then
        echo "Usage: grh <pattern>"
        return 1
    fi
    grep -rn ./ -e "$1"
}

# ------------------------------------------------------------------------------
# giveme - Recursively chown current directory to a user (default: current user)
# Usage: giveme [user:group]
# Example: giveme www-data:www-data
# ------------------------------------------------------------------------------
giveme() {
    local ME
    if [[ -z "$1" ]]; then
        ME="$(whoami):$(whoami)"
    else
        ME="$1"
    fi
    echo "Giving ownership to $ME"
    sudo chown "$ME" -R .
}

# ------------------------------------------------------------------------------
# say - Text-to-speech (cross-platform)
# Usage: say <text>
# macOS: uses native say; Linux: uses espeak
# ------------------------------------------------------------------------------
say() {
    if [[ -z "$1" ]]; then
        echo "Usage: say <text>"
        return 1
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        /usr/bin/say "$1"
    elif command -v espeak &>/dev/null; then
        echo "$1" | espeak -v fr 2>/dev/null
    else
        echo "say: no TTS engine found (espeak not installed?)"
        return 1
    fi
}
