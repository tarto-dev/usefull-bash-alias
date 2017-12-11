# System color & aliases #
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CFl'

# Folder navigation #
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"

# Drush related aliases #
alias dca='drush cc all --verbose'

alias c="clear"

### Benjamin's custom aliases ###

alias reload='source ~/.bashrc'
alias c='clear'
alias st='git st'
alias dcj='drush cc css-js'
alias dca='drush cc all'
alias ccss='sass --compass --scss -t nested'
alias gut='git'
alias got='git'

### Project aliases ###
alias www='cd /home/www/environnement_dev/bcassinat/code/front7/pressflow/sites; ls | /bin/grep ap2s'
alias www-psg='www & cd psg7.ap2s.fr'
alias www-revente='www && cd psgrevente7.ap2s.fr'

### Networking tools ###
# Stop after sending count ECHO_REQUEST packets #
alias ping='ping -c 5'

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

# older system use /proc/cpuinfo #
##alias cpuinfo='less /proc/cpuinfo'

# get GPU ram on desktop / laptop #
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

# resume wget by default #
alias wget='wget -c'

### Custom usefull functions ###

# Generate random password with X chars #
# $1 integer : chars count #
genpwd() { strings /dev/urandom | grep -o '[[:alnum:]]' | head -n "$1" | tr -d '\n'; echo; }

# Extract the file depends its format #
# $1 = filepath #
extract() {
    if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
          esac
    else
          echo "'$1' is not a valid file"
    fi
}

# Give a try :D #
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'

# Remove unused (already merged) branches #
# Edit Regex to fit to your needs
git-cleaner() { git branch --merged | grep -v -E "\bmaster|preprod|dmz\b" | xargs -n 1 git branch -d ;};

# Diff between 2 branches + ancestor #
# $1 = branch to review; $2 = file type filter, optional #
mdiff() { git diff origin/master..origin/$1 -- $2 ; }

# copy a file to the clipboard from the command line
function copyfile {
    cat $1 | xclip -selection clipboard
}

# shortcut for recursively grepping from "here"
function grh {
    grep -rn ./ -e $1
}
