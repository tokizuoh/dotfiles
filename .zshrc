export PATH="/opt/homebrew/bin:$PATH"

# Alias
alias ls='ls --color'
alias ghqcd='`ghq list --full-path | peco`'
alias gs='git status'
alias gsw='git switch `git branch | peco`'
alias tree='cmd="command tree -a -I .git"; echo $cmd; eval ${cmd}'
alias rmb='git branch --merged | xargs -n 1 | egrep -v "main|develop|\*" | xargs git branch -d'

# Other
setopt AUTO_CD

## `ls` when the current directory changes.
function chpwd() { ls }

## Insert two blank lines each time the command is executed
precmd () {
    print
    print
}

## Exclude frequently used commands before registering them in history
zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|ls|rm|rmdir|xed)($| )" ]]
}

if type rbenv > /dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi
