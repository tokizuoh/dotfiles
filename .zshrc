export PATH="/opt/homebrew/bin:$PATH"

# ref: https://github.com/sharkdp/bat
export BAT_THEME="Monokai Extended"

# ref: https://github.com/kylef/swiftenv/blob/1.5.0/docs/installation.md#via-homebrew
if which swiftenv > /dev/null; then eval "$(swiftenv init -)"; fi

for file in .zsh/*.zsh; do
    source "$file"
done

setopt AUTO_CD

# Insert two blank lines each time the command is executed
precmd () {
    print
    print
}

# Exclude frequently used commands before registering them in history
zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|ls|rm|rmdir|xed)($| )" ]]
}

if type rbenv > /dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi

# Added by Windsurf
export PATH="/Users/tokizo/.codeium/windsurf/bin:$PATH"
