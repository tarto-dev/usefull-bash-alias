# ==============================================================================
# Network functions
# ==============================================================================

# ------------------------------------------------------------------------------
# ssl - Display full SSL certificate details for a domain
# Usage: ssl <domain>
# Example: ssl example.com
# ------------------------------------------------------------------------------
ssl() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssl <domain>"
        return 1
    fi
    echo | openssl s_client -showcerts -servername "$1" -connect "$1":443 2>/dev/null \
        | openssl x509 -inform pem -noout -text
}

# ------------------------------------------------------------------------------
# ssl-test - Display SSL certificate validity dates for a domain
# Usage: ssl-test <domain>
# Example: ssl-test example.com
# ------------------------------------------------------------------------------
ssl-test() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssl-test <domain>"
        return 1
    fi
    echo | openssl s_client -connect "$1":443 -servername "$1" 2>/dev/null \
        | openssl x509 -noout -dates
}

# ------------------------------------------------------------------------------
# isdown - Check if a URL responds (HEAD request)
# Usage: isdown <url>
# Example: isdown https://example.com
# ------------------------------------------------------------------------------
isdown() {
    if [[ -z "$1" ]]; then
        echo "Usage: isdown <url>"
        return 1
    fi
    curl -X HEAD -i "$1"
}
