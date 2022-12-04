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

# git switch filter by peco
alias gsp='git switch `git branch | peco | sed -e "s/*//g"`'

# ghq, peco
alias ghqcd='`ghq list --full-path | peco`'

# Remove merged branch
alias rmmb='git branch --merged | xargs -n 1 | egrep -v "develop|\*" | xargs git branch -d'

# tree
alias tree='cmd="command tree -a -I .git"; echo $cmd; eval ${cmd}'

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

# Remove branch icon.
prompt_git() {
  # TODO: fix: [! -d .git]
  if [ -d .git ]; then
    local color ref
    is_dirty() {
      test -n "$(git status --porcelain --ignore-submodules)"
    }
    ref=`git branch --contains | cut -d " " -f 2`
    if [[ -n "$ref" ]]; then
      if is_dirty; then
        color=yellow
        ref="${ref}"
      else
        color=green
        ref="${ref}"
      fi
      if [[ "${ref/.../}" == "$ref" ]]; then
        ref="$ref"
      else
        ref="${ref/.../}"
      fi
      prompt_segment $color black
      print -n "$ref"
    fi
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
