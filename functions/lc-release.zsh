# ==============================================================================
# lc-release
# ==============================================================================
# Description:
#   Génère une liste des commits entre 2 références Git (branches/tags/refs),
#   triés selon les conventions Conventional Commits.
#
#   - Ignore les merges
#   - Trie par catégorie logique (feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert)
#   - Ajoute des emojis par type
#   - Format optimisé pour changelog / release notes
#   - Date courte: dd/mm/YYYY - HH:MM
#   - Auteur affiché en @username (déduit de l'email du commit)
#   - Liens cliquables vers GitLab (OSC8 ou Markdown) auto-déduits depuis "origin"
#   - Ticket best-effort (depuis message, optionnellement depuis nom de branche)
#
# Usage:
#   lc-release <target>
#     -> origin/(main|master)..<target>
#
#   lc-release <source> <destination>
#     -> <destination>..<source>
#        (affiche ce qui va être envoyé sur <destination> depuis <source>)
#
# Exemples:
#   lc-release feature/mon-ticket
#   lc-release origin/release
#   lc-release develop release
#   lc-release origin/develop origin/release
#
# Variables optionnelles:
#   LC_RELEASE_LINK_MODE="osc8"|"md"|"off"
#     - osc8: liens cliquables dans terminaux compatibles (iTerm2, Warp, VSCode…)
#     - md  : liens Markdown (pratique si tu pipes vers une MR / note)
#     - off : pas de liens
#     Par défaut: osc8 si stdout est un TTY, sinon md
#
#   LC_RELEASE_DEBUG=1
#     - logs origin url / host / path / project_url / user_base / range / link_mode
#
#   LC_RELEASE_TICKET_FROM_BRANCH=1
#     - si pas de ticket dans le message, tente de le déduire via:
#         git branch -r --contains <sha>
#       (⚠️ potentiellement lent selon le nombre de refs)
#
# Dépendances:
#   - git, awk, sort, sed, grep, tr
#   (protégées via chemins absolus sur macOS + fallback command -v)
#
# Bonnes pratiques:
#   - Faire un `git fetch --all` avant usage pour éviter les incohérences
#   - Respecter les Conventional Commits pour un tri propre
#
# Auteur: Clara
# ==============================================================================

lc-release() {
  local a="${1:-}"
  local b="${2:-}"

  if [ -z "$a" ]; then
    echo "Usage:"
    echo "  lc-release <target>"
    echo "  lc-release <source> <destination>"
    return 2
  fi

  # ---------------------------------------------------------------------------
  # Commandes (PATH-proof)
  # ---------------------------------------------------------------------------
  local GIT="/usr/bin/git"
  local AWK="/usr/bin/awk"
  local SORT="/usr/bin/sort"
  local SED="/usr/bin/sed"
  local GREP="/usr/bin/grep"
  local TR="/usr/bin/tr"

  if [ ! -x "$GIT" ];  then GIT="$(command -v git 2>/dev/null)";   fi
  if [ ! -x "$AWK" ];  then AWK="$(command -v awk 2>/dev/null)";   fi
  if [ ! -x "$SORT" ]; then SORT="$(command -v sort 2>/dev/null)"; fi
  if [ ! -x "$SED" ];  then SED="$(command -v sed 2>/dev/null)";   fi
  if [ ! -x "$GREP" ]; then GREP="$(command -v grep 2>/dev/null)"; fi
  if [ ! -x "$TR" ];   then TR="$(command -v tr 2>/dev/null)";     fi

  if [ -z "$GIT" ]  || [ ! -x "$GIT" ];  then echo "lc-release: git introuvable (PATH cassé ?)";  return 127; fi
  if [ -z "$AWK" ]  || [ ! -x "$AWK" ];  then echo "lc-release: awk introuvable (PATH cassé ?)";  return 127; fi
  if [ -z "$SORT" ] || [ ! -x "$SORT" ]; then echo "lc-release: sort introuvable (PATH cassé ?)"; return 127; fi
  if [ -z "$SED" ]  || [ ! -x "$SED" ];  then echo "lc-release: sed introuvable (PATH cassé ?)";  return 127; fi
  if [ -z "$GREP" ] || [ ! -x "$GREP" ]; then echo "lc-release: grep introuvable (PATH cassé ?)"; return 127; fi
  if [ -z "$TR" ]   || [ ! -x "$TR" ];   then echo "lc-release: tr introuvable (PATH cassé ?)";   return 127; fi

  "$GIT" fetch --all --prune >/dev/null 2>&1 || true

  # ---------------------------------------------------------------------------
  # Helpers Git refs
  # ---------------------------------------------------------------------------
  _lc_resolve_ref() {
    local ref="$1"
    if "$GIT" show-ref --verify --quiet "refs/remotes/$ref";        then echo "$ref";          return 0; fi
    if "$GIT" show-ref --verify --quiet "refs/heads/$ref";          then echo "$ref";          return 0; fi
    if "$GIT" show-ref --verify --quiet "refs/remotes/origin/$ref"; then echo "origin/$ref";  return 0; fi
    if "$GIT" show-ref --verify --quiet "refs/tags/$ref";           then echo "$ref";          return 0; fi
    return 1
  }

  # ---------------------------------------------------------------------------
  # GitLab URL auto-déduite depuis origin
  # ---------------------------------------------------------------------------
  _lc_origin_url() {
    "$GIT" remote get-url origin 2>/dev/null | "$TR" -d '\r'
  }

  _lc_detect_gitlab_host_path() {
    local origin host path
    origin="$(_lc_origin_url)"
    [ -z "$origin" ] && return 1

    if printf '%s' "$origin" | "$GREP" -Eq '^https?://'; then
      host="$(printf '%s' "$origin" | "$SED" -E 's#^https?://([^/]+)/.*#\1#')"
      path="$(printf '%s' "$origin" | "$SED" -E 's#^https?://[^/]+/(.*)#\1#' | "$SED" -E 's#\.git$##')"
      [ -n "$host" ] && [ -n "$path" ] || return 1
      printf '%s|%s\n' "$host" "$path"; return 0
    fi

    if printf '%s' "$origin" | "$GREP" -Eq '^ssh://'; then
      host="$(printf '%s' "$origin" | "$SED" -E 's#^ssh://[^@]+@([^/:]+)(:[0-9]+)?/.*#\1#')"
      path="$(printf '%s' "$origin" | "$SED" -E 's#^ssh://[^@]+@[^/]+/(.*)#\1#' | "$SED" -E 's#\.git$##')"
      [ -n "$host" ] && [ -n "$path" ] || return 1
      printf '%s|%s\n' "$host" "$path"; return 0
    fi

    if printf '%s' "$origin" | "$GREP" -Eq '^[^@]+@[^:]+:.+'; then
      host="$(printf '%s' "$origin" | "$SED" -E 's#^[^@]+@([^:]+):.*#\1#')"
      path="$(printf '%s' "$origin" | "$SED" -E 's#^[^@]+@[^:]+:(.*)#\1#' | "$SED" -E 's#\.git$##')"
      [ -n "$host" ] && [ -n "$path" ] || return 1
      printf '%s|%s\n' "$host" "$path"; return 0
    fi

    if printf '%s' "$origin" | "$GREP" -Eq '^[^:]+:.+'; then
      host="$(printf '%s' "$origin" | "$SED" -E 's#^([^:]+):.*#\1#')"
      path="$(printf '%s' "$origin" | "$SED" -E 's#^[^:]+:(.*)#\1#' | "$SED" -E 's#\.git$##')"
      printf '%s' "$path" | "$GREP" -q '/' || return 1
      [ -n "$host" ] && [ -n "$path" ] || return 1
      printf '%s|%s\n' "$host" "$path"; return 0
    fi

    return 1
  }

  # ---------------------------------------------------------------------------
  # Range
  # ---------------------------------------------------------------------------
  local range=""
  if [ -n "$b" ]; then
    local source_ref dest_ref
    source_ref="$(_lc_resolve_ref "$a")" || { echo "Ref introuvable: $a"; return 1; }
    dest_ref="$(_lc_resolve_ref "$b")"   || { echo "Ref introuvable: $b"; return 1; }
    range="${dest_ref}..${source_ref}"
  else
    local target_ref base_ref
    target_ref="$(_lc_resolve_ref "$a")" || { echo "Ref introuvable: $a"; return 1; }

    if "$GIT" show-ref --verify --quiet refs/remotes/origin/main; then
      base_ref="origin/main"
    elif "$GIT" show-ref --verify --quiet refs/remotes/origin/master; then
      base_ref="origin/master"
    else
      echo "Impossible de trouver origin/main ou origin/master"
      return 1
    fi

    range="${base_ref}..${target_ref}"
  fi

  # ---------------------------------------------------------------------------
  # URLs + Link mode
  # ---------------------------------------------------------------------------
  local host_path host path project_url user_base
  host_path="$(_lc_detect_gitlab_host_path 2>/dev/null)" || host_path=""
  host="${host_path%%|*}"
  path="${host_path#*|}"

  if [ -n "$host_path" ] && [ -n "$host" ] && [ -n "$path" ]; then
    project_url="https://${host}/${path}"
    user_base="https://${host}"
  else
    project_url=""
    user_base=""
  fi

  local link_mode="${LC_RELEASE_LINK_MODE:-}"
  if [ -z "$link_mode" ]; then
    if [ -t 1 ]; then link_mode="osc8"; else link_mode="md"; fi
  fi

  if [ "${LC_RELEASE_DEBUG:-0}" = "1" ]; then
    echo "[lc-release] origin url: $(_lc_origin_url)" >&2
    echo "[lc-release] parsed host: ${host:-<empty>}" >&2
    echo "[lc-release] parsed path: ${path:-<empty>}" >&2
    echo "[lc-release] project_url: ${project_url:-<empty>}" >&2
    echo "[lc-release] user_base: ${user_base:-<empty>}" >&2
    echo "[lc-release] range: $range" >&2
    echo "[lc-release] link_mode: $link_mode" >&2
    echo "[lc-release] ticket_from_branch: ${LC_RELEASE_TICKET_FROM_BRANCH:-0}" >&2
  fi

  # ---------------------------------------------------------------------------
  # Log -> tri -> rendu
  # ---------------------------------------------------------------------------
  "$GIT" log "$range" \
    --no-merges \
    --date=format:'%d/%m/%Y - %H:%M' \
    --pretty=format:"%h|%ae|%ad|%s" \
  | "$AWK" -F"|" \
      -v mode="$link_mode" \
      -v project="$project_url" \
      -v userbase="$user_base" \
      -v git="$GIT" \
      -v ticket_from_branch="${LC_RELEASE_TICKET_FROM_BRANCH:-0}" '
    function norm(msg,    m) {
      m = msg;
      sub(/^\[[^]]+\][[:space:]]+/, "", m);
      sub(/^[^A-Za-z]+[[:space:]]*/, "", m);
      return m;
    }

    function cat(msg,    m) {
      m = norm(msg);
      if (m ~ /^feat(\(.+\))?!?: /)     return 1;
      if (m ~ /^fix(\(.+\))?!?: /)      return 2;
      if (m ~ /^docs(\(.+\))?!?: /)     return 3;
      if (m ~ /^style(\(.+\))?!?: /)    return 4;
      if (m ~ /^refactor(\(.+\))?!?: /) return 5;
      if (m ~ /^perf(\(.+\))?!?: /)     return 6;
      if (m ~ /^test(\(.+\))?!?: /)     return 7;
      if (m ~ /^build(\(.+\))?!?: /)    return 8;
      if (m ~ /^ci(\(.+\))?!?: /)       return 9;
      if (m ~ /^chore(\(.+\))?!?: /)    return 10;
      if (m ~ /^revert(\(.+\))?!?: /)   return 11;
      return 99;
    }

    function emoji(msg,    m) {
      m = norm(msg);
      if (m ~ /^feat(\(.+\))?!?: /)     return "✨ feat";
      if (m ~ /^fix(\(.+\))?!?: /)      return "🐛 fix";
      if (m ~ /^docs(\(.+\))?!?: /)     return "📚 docs";
      if (m ~ /^style(\(.+\))?!?: /)    return "🎨 style";
      if (m ~ /^refactor(\(.+\))?!?: /) return "♻️ refactor";
      if (m ~ /^perf(\(.+\))?!?: /)     return "⚡ perf";
      if (m ~ /^test(\(.+\))?!?: /)     return "🧪 test";
      if (m ~ /^build(\(.+\))?!?: /)    return "🏗️ build";
      if (m ~ /^ci(\(.+\))?!?: /)       return "🤖 ci";
      if (m ~ /^chore(\(.+\))?!?: /)    return "🧹 chore";
      if (m ~ /^revert(\(.+\))?!?: /)   return "⏪ revert";
      return "• other";
    }

    function osc8(url, text) { return sprintf("\033]8;;%s\033\\%s\033]8;;\033\\", url, text); }
    function md(url, text)   { return "[" text "](" url ")"; }
    function link(url, text) {
      if (mode == "off" || url == "") return text;
      if (mode == "md") return md(url, text);
      return osc8(url, text);
    }

    function username_from_email(email,    at) {
      at = index(email, "@");
      if (at <= 1) return email;
      return substr(email, 1, at-1);
    }

    function ticket_from_message(msg,    m) {
      if (match(msg, /(\[#)[0-9]+(\])?/)) {
        m = substr(msg, RSTART, RLENGTH); gsub(/[^0-9]/, "", m); return m;
      }
      if (match(msg, /#[0-9]+/)) { return substr(msg, RSTART+1, RLENGTH-1); }
      if (match(msg, /[A-Z][A-Z0-9]+-[0-9]+/)) { return substr(msg, RSTART, RLENGTH); }
      if (match(msg, /(^|[^0-9])[0-9]{4,}[-_][A-Za-z0-9]/)) {
        m = substr(msg, RSTART, RLENGTH); gsub(/[^0-9]/, "", m); return m;
      }
      if (match(msg, /[A-Za-z0-9][-_][0-9]{4,}([^0-9]|$)/)) {
        m = substr(msg, RSTART, RLENGTH); gsub(/[^0-9]/, "", m); return m;
      }
      return "";
    }

    function ticket_from_containing_branch(sha,    cmd, line, t) {
      cmd = git " branch -r --contains " sha " 2>/dev/null";
      while ((cmd | getline line) > 0) {
        gsub(/^[ \t*]+/, "", line);
        if (line !~ /^origin\//) continue;
        if (match(line, /origin\/[0-9]{4,}[-_][A-Za-z0-9]/)) {
          t = substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", t); close(cmd); return t;
        }
        if (match(line, /origin\/[A-Z][A-Z0-9]+-[0-9]+/)) {
          t = substr(line, RSTART+7, RLENGTH-7); close(cmd); return t;
        }
        if (match(line, /origin\/[A-Za-z0-9._\/-]+[-_][0-9]{4,}/)) {
          t = substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", t); close(cmd); return t;
        }
      }
      close(cmd); return "";
    }

    function format_ticket(t) {
      if (t == "") return "";
      if (t ~ /^[A-Z][A-Z0-9]+-[0-9]+$/) return "[" t "] ";
      if (t ~ /^[0-9]+$/) return "[#" t "] ";
      return "[" t "] ";
    }

    {
      sha=$1; email=$2; date=$3; msg=$4;
      c = cat(msg);
      e = emoji(msg);

      t = ticket_from_message(msg);
      if (t == "" && ticket_from_branch == "1") { t = ticket_from_containing_branch(sha); }
      ticket_prefix = format_ticket(t);

      if (norm(msg) ~ /^[a-z]+(\(.+\))?!?: /) {
        sub(/^[^A-Za-z]*[a-z]+(\(.+\))?!?: /, ticket_prefix e " — ", msg);
      } else {
        msg = ticket_prefix msg;
      }

      user = username_from_email(email);
      user_display = "@" user;
      sha_url  = (project != "" ? project "/-/commit/" sha : "");
      user_url = (userbase != "" ? userbase "/" user : "");
      sha_out  = link(sha_url, sha);
      user_out = link(user_url, user_display);

      printf "%02d|%s|%s|%s|%s\n", c, sha_out, user_out, date, msg;
    }
  ' \
  | "$SORT" -t"|" -k1,1n -k5,5 \
  | "$AWK" -F"|" '{ printf "%-10s %-18s %-18s %.90s\n", $2, $3, $4, $5 }'
}
