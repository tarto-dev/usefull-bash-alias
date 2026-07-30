#!/usr/bin/env bash
# Merge mantis-release + lc-release outputs into a single copy/paste block.
#
# Usage:
#   release-notes                              # origin/release vs origin/master
#   release-notes <source>                     # <source> vs origin/master
#   release-notes <source> <destination>
#
# Env:
#   RELEASE_NOTES_AUTHOR_MAP="contact:mmaingret,foo:bar"
#       Remap @username tokens in commit lines.
#       Defaults to "contact:mmaingret".

set -u

SOURCE="${1:-origin/release}"
DEST="${2:-origin/master}"

AUTHOR_MAP="${RELEASE_NOTES_AUTHOR_MAP:-contact:mmaingret}"

# --- helpers ----------------------------------------------------------------

strip_ansi() {
  # remove SGR + OSC 8 hyperlink escapes
  sed -E $'s/\x1b\\][0-9]+;[^\x1b]*\x1b\\\\//g; s/\x1b\\[[0-9;]*[A-Za-z]//g'
}

apply_author_map() {
  local input="$1"
  local IFS=','
  for pair in $AUTHOR_MAP; do
    [ -z "$pair" ] && continue
    local from="${pair%%:*}"
    local to="${pair#*:}"
    [ -z "$from" ] || [ -z "$to" ] && continue
    input="${input//@${from}/@${to}}"
  done
  printf '%s' "$input"
}

emoji_to_shortcode() {
  # Convert unicode emojis used by lc-release to gitmoji shortcodes.
  sed \
    -e 's/✨/:sparkles:/g' \
    -e 's/🐛/:bug:/g' \
    -e 's/📚/:books:/g' \
    -e 's/🎨/:art:/g' \
    -e 's/♻️/:recycle:/g' \
    -e 's/♻/:recycle:/g' \
    -e 's/⚡️/:zap:/g' \
    -e 's/⚡/:zap:/g' \
    -e 's/🧪/:test_tube:/g' \
    -e 's/🏗️/:building_construction:/g' \
    -e 's/🏗/:building_construction:/g' \
    -e 's/🤖/:robot:/g' \
    -e 's/🧹/:broom:/g' \
    -e 's/⏪/:rewind:/g'
}

# --- run sub-commands -------------------------------------------------------

# mantis-release is a zsh alias to a script — invoke the script directly.
MANTIS_SCRIPT="$HOME/.dotfiles/ext/mantis-release.sh"
if [ ! -x "$MANTIS_SCRIPT" ] && [ -f "$MANTIS_SCRIPT" ]; then
  chmod +x "$MANTIS_SCRIPT" 2>/dev/null || true
fi

mantis_out="$("$MANTIS_SCRIPT" "$SOURCE" "$DEST" 2>/dev/null)"

# lc-release is a zsh function — source its definition non-interactively.
LC_RELEASE_FN="$HOME/.dotfiles/functions/lc-release.zsh"
lc_out="$(LC_RELEASE_LINK_MODE=off zsh -f -c "source '$LC_RELEASE_FN'; lc-release '$SOURCE' '$DEST'" 2>/dev/null | strip_ansi)"

# --- tickets section --------------------------------------------------------

tickets_block="$(printf '%s\n' "$mantis_out" \
  | awk '/^🐛 Fix\/features|^🔖 Fix\/features/{p=1} p{print}' \
  | sed -E 's/[[:space:]]+$//')"

# --- commits section --------------------------------------------------------

commits_block="$(
  printf '%s\n' "$lc_out" \
    | awk 'NF' \
    | sed -E 's/[[:space:]]+$//' \
    | sed -E 's/[[:space:]]{2,}/ /g' \
    | emoji_to_shortcode \
    | while IFS= read -r line; do
        apply_author_map "$line"
        printf '\n'
      done \
    | sed -E 's/^/- /'
)"

# --- final assembly ---------------------------------------------------------

cat <<EOF
Tickets:

\`\`\`
$tickets_block
\`\`\`

Commits:

$commits_block
EOF
