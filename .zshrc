# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"


#########
# Theme #
#########
ZSH_THEME="agnoster"


##########
# Plugin #
##########
plugins=(git)


#########
# Alias #
#########

# git status
alias gs='git status'

# ghq, peco
alias ghqcd='cd $(ghq list --full-path | peco)'

# Reboot shell
alias resh='echo -e --REBOOT SHELL--;exec $SHELL -l'

# Remove merged branch
alias rmmb='git branch --merged | xargs -n 1 | egrep -v "develop|\*" | xargs git branch -d'


#########
# Other #
#########
source $ZSH/oh-my-zsh.sh
