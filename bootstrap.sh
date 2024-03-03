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
    if [ ! -e /opt/homebrew-x86_64 ]; then
        sudo mkdir /opt/homebrew-x86_64
        sudo chown `whoami`:staff /opt/homebrew-x86_64
        curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C /opt/homebrew-x86_6
    fi
    brew bundle
fi

# Visual Studio Code
ln -sfnv ${PWD}/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sfnv ${PWD}/.vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

cat ${PWD}/.vscode/extensions.txt | while read line
do
    code --install-extension $line
done

# .gitconfig
ln -sfnv ${PWD}/.gitconfig ~/.gitconfig

# .gitignore_global
git config --global core.excludesfile ~/.gitignore_global
ln -sfnv ${PWD}/.gitignore_global ~/.gitignore_global
