#!/bin/zsh

set -eu

BASEDIR=$(dirname $0)
cd $BASEDIR

for f in .??*; do
    [ "$f" = ".git" ] && continue
    ln -sfnv ${PWD}/${f} $HOME/${f}
done

#Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle

# # VSCode
# ln -sfnv ${PWD}/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
# ln -sfnv ${PWD}/.vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json