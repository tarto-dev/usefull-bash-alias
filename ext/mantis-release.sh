#!/bin/bash

# ======================== Configuration ========================
MANTIS_URL="https://mantis.gingerminds.fr"
MANTIS_TOKEN="wkVpbSrqU7paYvmNL7Qmy7KLgmJxrBIB"

if [ -z "$MANTIS_TOKEN" ]; then
  echo "❌ Erreur : la variable d'environnement MANTIS_TOKEN n'est pas définie."
  echo "   Ajoute dans ton .bashrc / .zshrc :"
  echo "   export MANTIS_TOKEN=\"ton_token_ici\""
  exit 1
fi

# ======================== Options ========================
DEBUG=false
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --debug|-d) DEBUG=true ;;
    *) ARGS+=("$arg") ;;
  esac
done

debug() { $DEBUG && echo "  [DEBUG] $*" >&2; }

# ======================== Branches ========================
BRANCH_RIGHT="${ARGS[0]:-origin/release}"
BRANCH_LEFT="${ARGS[1]:-origin/master}"

# Vérifie que les branches existent
for branch in "$BRANCH_LEFT" "$BRANCH_RIGHT"; do
  if ! git rev-parse --verify "$branch" > /dev/null 2>&1; then
    echo "❌ Erreur : la branche '$branch' n'existe pas."
    exit 1
  fi
done

echo "🔍 Comparaison : ${BRANCH_RIGHT} > $BRANCH_LEFT"
echo ""

# ======================== Extraction des IDs ========================
SUBJECTS=$(git log "$BRANCH_LEFT"..."$BRANCH_RIGHT" \
  --cherry-pick --right-only --pretty=format:"%s")

debug "=== Sujets des commits ==="
$DEBUG && echo "$SUBJECTS" | sed 's/^/  /' >&2
debug ""

IDS=$(echo "$SUBJECTS" \
  | grep -oE '#[0-9]{5,7}|\([0-9]{5,7}\)|feat/[0-9]{5,7}|feature/[0-9]{5,7}|fix/[0-9]{5,7}' \
  | grep -oE '[0-9]{5,7}' \
  | sed 's/^0*//' \
  | grep -v '^$' \
  | sort -un)

debug "=== IDs extraits ==="
$DEBUG && echo "$IDS" | sed 's/^/  /' >&2
debug ""

UNNAMED=$(echo "$SUBJECTS" \
  | grep -oE '(feat|feature|fix)/[a-zA-Z][a-zA-Z0-9_-]*' \
  | sort -u)

debug "=== Branches sans numéro ==="
$DEBUG && echo "$UNNAMED" | sed 's/^/  /' >&2
debug ""

if [ -z "$IDS" ] && [ -z "$UNNAMED" ]; then
  echo "✅ Aucun ticket trouvé entre $BRANCH_LEFT et $BRANCH_RIGHT."
  exit 0
fi

# ======================== Appel API Mantis + affichage ========================
if [ -n "$IDS" ]; then
  echo "🐛 Fix/features avec numéro de ticket :  "
  while read -r id; do
    debug "curl $MANTIS_URL/api/rest/issues/$id"
    response=$(curl -s \
      -H "Authorization: $MANTIS_TOKEN" \
      "$MANTIS_URL/api/rest/issues/$id")

    summary=$(echo "$response" | jq -r '.issues[0].summary // empty')

    if [ -z "$summary" ]; then
      echo "   • #$id - ⚠️ Ticket introuvable ou accès refusé ($MANTIS_URL/view.php?id=$id)  "
    else
      echo "   • #$id - $summary => $MANTIS_URL/view.php?id=$id  "
    fi
  done <<< "$IDS"
fi

# ======================== Fix/features sans numéro ========================
if [ -n "$UNNAMED" ]; then
  [ -n "$IDS" ] && echo ""
  echo "🔖 Fix/features sans numéro de ticket :  "
  while read -r branch; do
    echo "   • $branch  "
  done <<< "$UNNAMED"
fi

