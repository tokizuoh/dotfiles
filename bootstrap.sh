#!/bin/zsh

set -eu

BASEDIR=$(dirname $0)
cd $BASEDIR

for f in .??*; do
    [ "$f" = ".git" ] && continue
    ln -sfnv ${PWD}/${f} $HOME/${f}
done

# Homebrew
if test `uname -m` = "arm64"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew bundle
else
    echo "Under construction..."
fi

# VSCode
ln -sfnv ${PWD}/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sfnv ${PWD}/.vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# .gitignore_global
git config --global core.excludesfile ~/.gitignore_global
ln -sfnv ${PWD}/.gitignore_global ~/.gitignore_global
