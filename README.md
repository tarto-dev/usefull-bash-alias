# usefull-bash-alias

Personal Unix shell configuration — zsh aliases, functions, and tooling.

## Structure

```
.
├── install.sh              # One-shot installer (macOS + Linux)
├── zsh/
│   └── .zshrc              # Main zsh config (symlinked to ~/.zshrc)
├── aliases/
│   ├── system.zsh          # Navigation, shell, modern CLI (bat, eza...)
│   ├── git.zsh             # Git shortcuts and log formats
│   ├── macos.zsh           # macOS-only aliases (guarded)
│   └── linux.zsh           # Linux-only aliases (guarded)
├── functions/
│   ├── git.zsh             # git-nb, git-eb, git-cleaner, mdiff, compare, up
│   ├── lc-release.zsh      # Conventional commits changelog generator
│   ├── files.zsh           # extract, copyfile, zero-byte
│   ├── network.zsh         # ssl, ssl-test, isdown
│   └── utils.zsh           # genpwd, grh, giveme, say
├── ext/
│   └── smart-commit.zsh    # AI-powered git commits via Claude Code
└── ssh/
    └── aliases.zsh         # SSH aliases — gitignored, local only
```

## Installation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tarto-dev/usefull-bash-alias/master/install.sh)"
```

The installer handles:
- Homebrew (macOS)
- Oh My Zsh + Powerlevel10k
- zsh plugins (autosuggestions, syntax-highlighting, history-enquirer)
- CLI tools: bat, eza, fzf, zoxide, thefuck, fortune, ponysay, lolcat
- Kaamelott fortunes
- Symlinks

## SSH aliases

`ssh/aliases.zsh` is gitignored. Create it locally:

```bash
cp ~/.dotfiles/ssh/aliases.zsh.example ~/.dotfiles/ssh/aliases.zsh
# then fill in your own aliases
```

## Key functions

| Function | Usage |
|---|---|
| `lc-release <branch>` | Changelog depuis master vers une branche |
| `smart-commit` | Commits atomiques via Claude Code |
| `extract <file>` | Extraction auto selon extension |
| `copyfile <file>` | Copie dans le clipboard (macOS/Linux) |
| `ssl <domain>` | Détails certificat SSL |
| `genpwd <n>` | Génère un mot de passe aléatoire |
| `git-nb <branch>` | Crée et push une nouvelle branche |
| `git-cleaner` | Supprime les branches déjà mergées |
