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

# Insert two blank lines each time the command is executed.
precmd () {
        print
        print
}

# `ls` when the current directory changes.
function chpwd() { ls }

# Disable automatic upgrade confirmation for oh-my-zsh.
DISABLE_AUTO_UPDATE="true"

# Hide username and hostname.
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
  fi
}

# Add new line.
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
      print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
      print -n "%{%k%}"
  fi

  print -n "%{%f%}"
  CURRENT_BG=''

  printf "\n>";
}
