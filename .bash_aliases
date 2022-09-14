#!/bin/bash 

# some more ls aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CFlh'

# Folder navigation #
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"

### My own custom aliases ###
alias reload='source ~/.bashrc'
alias r='reload'
alias vimbash='vim ~/.bashrc'
alias vimalias='vim ~/.bash_aliases'
alias c='clear'
alias st='git st'
alias gd='git diff'
alias gut='git'
alias got='git'
alias ccat='pygmentize'

### Project aliases ###
alias www='cd /home/benftwc/www'

### Networking tools ###
# Stop after sending count ECHO_REQUEST packets #
alias ping='ping -c 5'
alias wget='wget -c'

# Do not wait interval 1 second, go fast #
alias fastping='ping -c 100 -s.2'

### Curl Debugger ##
# get web server headers #
alias header='curl -I'

# find out if remote server supports gzip / mod_deflate or not #
alias headerc='curl -I --compress'

### System user management ###
# become root #
alias root='sudo -i'
alias su='sudo -i'

### System usage infos ###
# pass options to free #
alias meminfo='free -m -l -t'

# get top process eating memory #
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

# get top process eating cpu #
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

# Get server cpu info #
alias cpuinfo='lscpu'

# get GPU ram on desktop / laptop #
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

# Python 
alias python="python3"
alias pip="pip3"

## Fun stuff ##
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'
alias please="sudo"

# Remove unused (already merged) branches #
# Edit Regex to fit to your needs
git-cleaner() { git branch --merged | grep -v -E "\bmaster|preprod|dmz|dev\b" | xargs -n 1 git branch -d ;};

## Git branch management ##
# Diff between 2 branches + ancestor #
# $1 = branch to review; 
# $2 = file type filter, optional 
# $3 = diff options (--stat, --name-only ...)
mdiff() { git diff "$3" origin/master..origin/"$1" -- "$2" ; }

# git-nb branch-name : Create new branch & push it to the origin server
git-nb() { git checkout master && git pull && git checkout -b "$1" && git push origin "$1" -u; };

# git-eb remote-branch-name : Checkout the latest state for given branch
git-eb() { git checkout master && git fetch --all --prune && git checkout -b "$1" origin/"$1"; };


### Other usefull commands ###
# copy a file to the clipboard from the command line
function copyfile {
    cat "$1" | xclip -selection clipboard
}

# shortcut for recursively grepping from "here"
function grh {
    grep -rn ./ -e "$1"
}

### Custom usefull functions ###

# Generate random password with X chars ($1) #
# usage : genpwd digits
# example : genpwd 12
genpwd() { strings /dev/urandom | grep -o '[[:alnum:]]' | head -n "$1" | tr -d '\n'; echo; }

# Extract the file depends its format #
extract() {
    if [ -f "$1" ] ; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
	    *.tar.xz)    tar xjf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
          esac
    else
          echo "'$1' is not a valid file"
    fi
};

### Git management system ###
# Diff between 2 branches + ancestor #
# usage : mdiff ancestor-branch files-pattern options
# example : mdiff preprod *.scss --ignore-whitespaces
mdiff() { git diff "$3" origin/master..origin/"$1" -- "$2" ; }

compare() { git diff origin/master...origin/"$1" --stat ; }

# Git branch management #
# git-nb branch-name : Create new branch & push it to the origin server
# usage : git-nb branch-name
git-nb() { git checkout master && git pull && git checkout -b "$1" && git push origin "$1" -u; };

# git-eb remote-branch-name : Checkout the latest state for given branch
# usage : git-eb branch-name
git-eb() { git checkout master && git fetch --all --prune && git checkout -b "$1" origin/"$1"; };

# git-rmc : Remove pushed commit
# usage : git-rmc branch-name commitID
git-rmc() { git checkout master && git fetch --all --prune && git push origin +"$2"^:"$1"; }

# Remove unused (already merged) branches #
# usage : git-cleaner()
git-cleaner() { git branch --merged | grep -v -E "\bmaster|preprod|dev\b" | xargs -n 1 git branch -d ;}

# Check wether or not a commit is merged
# usage : git-merged commit-id
git-merged() { git fetch --all; git branch --contains "$1"; };

# Switch between INFRA & INTER modes for git@teclib
git-vpn() {
     if git remote -v | grep -q "teclib.com"; then
        git remote set-url origin git@gitlab.teclib.infra:buweb/ciffco-preprod.git
        echo "$__CYAN" "Changement d'URL pour git. Mode""$__GREEN" "INFRA on""$__CYAN"
        git remote -v;
    else
        git remote set-url origin http://gitlab.teclib.com/buweb/ciffco-preprod.git
        echo "$__CYAN" "Changement d'URL pour git. Mode""$__RED" "INFRA off""$__CYAN"
        git remote -v;
    fi
}

# Create new Docker instance (teclib related)
docker-clone() {
	git clone --depth=1 --branch=master git@gitlab.buy-the-way.com:docker/docker.git "$1"
	rm -rf !$/.git
}

ytdl() {
	cd ~/Music || exit
	youtube-dl -x --audio-format mp3 "$1"
	cd - || exit
}

say() {
        echo "$1" | espeak -v fr 2>/dev/null
}

ssl() {
    echo | openssl s_client -showcerts -servername "$1" -connect "$1":443 2>/dev/null | openssl x509 -inform pem -noout -text    
}

alias vim-update="vim +PluginInstall +qall"

alias sql-date="date '+%Y-%m-%d_%H:%M:%S'"

alias up='find . -type d -name .git -exec sh -c "cd \"{}\"/../ && pwd && git pull" \;'

ssl-test() {
    echo | openssl s_client -connect "$1":443 -servername "$1" 2>/dev/null | openssl x509 -noout -dates;
}

isdown() {
	curl -X HEAD -i $1
}

giveme() {
    if [ -z "$1" ]; then
        ME=$(whoami):$(whoami)
    else
        ME=$1
    fi
    echo "Give whole to $ME"
    sudo chown $ME -R .
}

zero-byte() {
    find $1 -size 0 -print
}
