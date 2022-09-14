# Add into existing .bashrc / .bash_profile

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Add PS1 if exists
if [ -f ~/.bash_ps1 ]; then
    . ~/.bash_ps1
fi
