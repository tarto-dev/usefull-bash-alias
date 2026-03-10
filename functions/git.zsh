# ==============================================================================
# Git functions
# ==============================================================================

# ------------------------------------------------------------------------------
# git-nb - Create new branch and push to origin
# Usage: git-nb <branch-name>
# ------------------------------------------------------------------------------
git-nb() {
    if [[ -z "$1" ]]; then
        echo "Usage: git-nb <branch-name>"
        return 1
    fi
    git checkout master && git pull && git checkout -b "$1" && git push origin "$1" -u
}

# ------------------------------------------------------------------------------
# git-eb - Checkout latest state for a remote branch
# Usage: git-eb <branch-name>
# ------------------------------------------------------------------------------
git-eb() {
    if [[ -z "$1" ]]; then
        echo "Usage: git-eb <branch-name>"
        return 1
    fi
    git checkout master && git fetch --all --prune && git checkout -b "$1" origin/"$1"
}

# ------------------------------------------------------------------------------
# git-rmc - Remove a pushed commit
# Usage: git-rmc <branch-name> <commit-id>
# ------------------------------------------------------------------------------
git-rmc() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: git-rmc <branch-name> <commit-id>"
        return 1
    fi
    git checkout master && git fetch --all --prune && git push origin +"$2"^:"$1"
}

# ------------------------------------------------------------------------------
# git-cleaner - Remove local branches already merged into current branch
# Usage: git-cleaner
# ------------------------------------------------------------------------------
git-cleaner() {
    git branch --merged | grep -v -E "\bmaster|preprod|dev\b" | xargs -n 1 git branch -d
}

# ------------------------------------------------------------------------------
# git-merged - Check if a commit is merged and in which branches
# Usage: git-merged <commit-id>
# ------------------------------------------------------------------------------
git-merged() {
    if [[ -z "$1" ]]; then
        echo "Usage: git-merged <commit-id>"
        return 1
    fi
    git fetch --all
    git branch --contains "$1"
}

# ------------------------------------------------------------------------------
# mdiff - Diff between current branch and another, relative to master
# Usage: mdiff <branch> [file-pattern] [diff-options]
# Example: mdiff preprod *.scss --ignore-whitespace
# ------------------------------------------------------------------------------
mdiff() {
    if [[ -z "$1" ]]; then
        echo "Usage: mdiff <branch> [file-pattern] [diff-options]"
        return 1
    fi
    git diff "$3" origin/master..origin/"$1" -- "$2"
}

# ------------------------------------------------------------------------------
# compare - Stat diff between master and a branch (ancestor-aware)
# Usage: compare <branch>
# ------------------------------------------------------------------------------
compare() {
    if [[ -z "$1" ]]; then
        echo "Usage: compare <branch>"
        return 1
    fi
    git diff origin/master...origin/"$1" --stat
}

# ------------------------------------------------------------------------------
# up - Pull all git repos found recursively from current directory
# Usage: up
# ------------------------------------------------------------------------------
unalias up 2>/dev/null
up() {
    find . -type d -name .git -exec sh -c 'cd "{}"/../ && pwd && git pull' \;
}
