# --------------------------------------------------------------------------------------------------------------
# smart-commit - AI-Powered Git Commits with Claude Code
# --------------------------------------------------------------------------------------------------------------
# A zsh function that uses Claude Code to analyze your git changes and create
# logical, atomic commits following conventional commits format.
#
# Requirements:
#   - Claude Code CLI installed (https://github.com/anthropics/claude-code)
#   - Git installed
#   - zsh shell
#
# Installation:
#   source ~/zshext/smart-commit.zsh from ~/.zshrc
#
# Usage:
#   smart-commit                  # standard (haiku)
#   smart-commit -s               # smart mode (sonnet, for complex diffs)
#   smart-commit "context note"   # with optional context
#   smart-commit -s "context"     # both
# --------------------------------------------------------------------------------------------------------------
smart-commit() {
    # --- Guards ---
    if ! command -v claude &>/dev/null; then
        echo "❌ claude CLI not found in PATH" >&2
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "❌ Not inside a git repository" >&2
        return 1
    fi

    # --- Args parsing ---
    local use_sonnet=false
    local context=""

    for arg in "$@"; do
        case "$arg" in
            -s|--smart) use_sonnet=true ;;
            *) context="$arg" ;;
        esac
    done

    local model="haiku"
    if $use_sonnet; then
        model="sonnet"
        echo "🧠 Smart mode: using Sonnet"
    fi

    # --- Ticket extraction ---
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    local ticket
    ticket=$(echo "$branch" | grep -oE '[0-9]{5}')

    if [ -n "$ticket" ]; then
        echo "🎫 Ticket detected: #$ticket (from branch: $branch)"
    else
        echo "⚠️  No 5-digit ticket found in branch name: '$branch'"
        echo -n "   Enter ticket number (5 digits, or press Enter to skip): "
        read -r ticket
        if [ -n "$ticket" ] && ! echo "$ticket" | grep -qE '^[0-9]{5}$'; then
            echo "❌ Invalid ticket number. Aborting." >&2
            return 1
        fi
        if [ -z "$ticket" ]; then
            echo "ℹ️  No ticket — commits will be created without ticket reference"
        fi
    fi

    # --- Prompt ---
    local ticket_instruction
    if [ -n "$ticket" ]; then
        ticket_instruction="Ticket number is #${ticket} — include [#${ticket}] in every commit title."
    else
        ticket_instruction="No ticket associated — do NOT include any ticket reference in commit titles."
    fi

    local prompt="Analyze git changes and create logical, atomic commits using conventional commits format. ${ticket_instruction}"
    if [ -n "$context" ]; then
        prompt="$prompt Context: $context"
    fi

    # --- Run ---
    claude "$prompt" \
        --allowedTools "Bash(git status:*)" \
                       "Bash(git diff:*)" \
                       "Bash(git add:*)" \
                       "Bash(git commit:*)" \
                       "Bash(git branch:*)" \
                       "Read" \
        --disallowedTools "Bash(git push:*)" \
                          "Bash(git reset:*)" \
                          "Bash(git revert:*)" \
                          "Bash(git clean:*)" \
                          "Bash(git rebase:*)" \
                          "Bash(git merge:*)" \
                          "Bash(git checkout:*)" \
                          "Bash(rm:*)" \
                          "Bash(mv:*)" \
                          "Write" \
                          "Edit" \
        --model="$model" \
        --append-system-prompt "STRICT RULES:
1. ONLY use git status, git diff, git add, git commit, and git branch commands
2. Use conventional commits with gitmoji prefix (optional but recommended): ✨feat|🐛fix|📝docs|🎨style|♻️refactor|⚡️perf|🧪test|📦build|👷ci|🧹chore|⏪revert
3. Format: <gitmoji> <type>(<scope>): <description> [#NNNNN] (description max ~72 chars, imperative present tense)
4. Follow ticket instructions from the prompt: if a ticket is provided, include [#NNNNN] in every commit title; if explicitly told no ticket, omit any ticket reference entirely
5. One logical change per commit — atomic and focused
6. For breaking changes: add ! after type/scope AND include BREAKING CHANGE footer
7. After each commit, verify with git status
8. NEVER stage or commit: .idea/, .vscode/, *.lock files unless explicitly modified intentionally
9. If git diff --staged is empty after git add, do NOT commit

WORKFLOW:
- Examine changes with git status and git diff
- Plan commits (announce your strategy)
- Execute commits one by one
- Add Refs or Closes footer with Mantis link when relevant: Refs: [#NNNNN](https://mantis.gingerminds.fr/view.php?id=NNNNN)
- Provide summary of completed commits

EXAMPLES:
- ✨ feat(auth): add JWT token validation [#12345]
- 🐛 fix(api): resolve memory leak on upload [#12346]
- 📝 docs(readme): update local setup instructions [#12347]
- ♻️ refactor(utils): extract shared validation logic [#12348]
- ✨ feat(config)!: change storage directory structure [#12349]
  BREAKING CHANGE: existing deployments must migrate storage paths"
}
