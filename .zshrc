export PATH="/opt/homebrew/bin:$PATH"

# Git prompt function
function git_prompt_info() {
    local branch=$(git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
    if [ -n "$branch" ]; then
        echo " git:(%F{#C7DC68}$branch%f)"
    fi
}

# Custom prompt
setopt PROMPT_SUBST
PROMPT='%B%F{#00A0FF}%~%f$(git_prompt_info)%b
'

# Set input text color to bright white
zle_highlight=(default:fg=white,bold)

# ref: https://github.com/sharkdp/bat
export BAT_THEME="Monokai Extended"

# ref: https://github.com/kylef/swiftenv/blob/1.5.0/docs/installation.md#via-homebrew
if which swiftenv > /dev/null; then eval "$(swiftenv init -)"; fi

# Alias
alias ls='ls --color=auto'
alias ghqcd='`ghq list --full-path | peco`'
alias gs='git status'
alias gsw='git switch `git branch | peco`'
alias gswpr='peco-checkout-pull-request'
alias gswd='switch-default-branch-if-exists'
alias gbr='git branch --show-current'
alias gus='git reset HEAD --'
alias tree='cmd="command tree -a -I .git"; echo $cmd; eval ${cmd}'
alias rmb='git branch --merged | xargs -n 1 | egrep -v "main|develop|\*" | xargs git branch -d'
alias rm='trash'
alias aed='open -a "Android Studio"'

# Other
setopt AUTO_CD

## Do `ls` when the current directory changes.
function chpwd() { ls }

## Insert two blank lines each time the command is executed
precmd () {
    print
    print

    # Check for uncommitted changes in dotfiles
    local dotfiles_dir="$HOME/ghq/github.com/tokizuoh/dotfiles"
    if [ -d "$dotfiles_dir" ]; then
        local changes
        changes=$(git -C "$dotfiles_dir" status --porcelain)
        if [ -n "$changes" ]; then
            echo "\033[37m+---------------------------------------------------------------+"
            echo "| ⚠️  Warning: dotfiles have uncommitted changes!                |"
            echo "| Commit them now!                                              |"
            echo "+---------------------------------------------------------------+"
            echo ""
            echo "Changed files:"
            echo "$changes" | sed 's/^/- /'
            echo "\033[0m"
        fi
    fi
}

## Exclude frequently used commands before registering them in history
zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|ls|rm|rmdir|xed)($| )" ]]
}

if type rbenv > /dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi

if type mise > /dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

## Checkout PR branch
function peco-checkout-pull-request () {
    local selected_pr_id=$(gh pr list | peco | awk '{ print $1 }')
    if [ -n "$selected_pr_id" ]; then
        gh pr checkout $selected_pr_id
    fi
}

## Switch default branch
function switch-default-branch-if-exists () {
    local git_directory=$(git rev-parse --show-toplevel)
    if [ -e "$git_directory/.git/refs/remotes/origin/HEAD" ]; then
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
        git switch $default_branch
    else
        echo "refs/remotes/origin/HEAD does not exist."
    fi
}

## nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## nest
export PATH="$HOME/.nest/bin:$PATH"
export LEFTHOOK=0

export ANDROID_HOME="$HOME/Library/Android/sdk"

export PATH="$HOME/.local/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
