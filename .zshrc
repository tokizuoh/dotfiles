export PATH="/opt/homebrew/bin:$PATH"

# Alias
alias ls='ls --color'
alias ghqcd='`ghq list --full-path | peco`'
alias gs='git status'
alias tree='cmd="command tree -a -I .git"; echo $cmd; eval ${cmd}'

# Other
setopt AUTO_CD

## `ls` when the current directory changes.
function chpwd() { ls }

## Insert two blank lines each time the command is executed
precmd () {
    print
    print
}
