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
    if ! type "brew" > /dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
else
    if [ ! -e /opt/homebrew-x86_64 ]; then
        sudo mkdir /opt/homebrew-x86_64
        sudo chown `whoami`:staff /opt/homebrew-x86_64
        curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C /opt/homebrew-x86_6
    fi
fi
brew bundle

# Visual Studio Code
ln -sfnv ${PWD}/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sfnv ${PWD}/.vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# Xcode
ln -sfnv ${PWD}/.xcode/IDETemplateMacros.plist ~/Library/Developer/Xcode/UserData/IDETemplateMacros.plist

# .gitconfig
ln -sfnv ${PWD}/.gitconfig ~/.gitconfig

# .gitignore_global
git_config_path=${HOME}/.config/git
if [ ! -d "$git_config_path" ]; then
  mkdir -p "$git_config_path"
  touch ${git_config_path}/ignore
fi
ln -sfnv ${PWD}/.gitignore_global ${git_config_path}/ignore

# WezTerm
wezterm_config_path=${HOME}/.config/wezterm
if [ ! -d "$wezterm_config_path" ]; then
  mkdir -p "$wezterm_config_path"
fi
ln -sfnv ${PWD}/wezterm/wezterm.lua ${wezterm_config_path}/wezterm.lua

# AI agent instructions
agents_md=${PWD}/AGENTS.md

claude_config_path=${HOME}/.claude
if [ ! -d "$claude_config_path" ]; then
  mkdir -p "$claude_config_path"
fi
ln -sfnv ${agents_md} ${claude_config_path}/CLAUDE.md

# Claude settings & statusline
ln -sfnv ${PWD}/claude/statusline.sh ${claude_config_path}/statusline.sh
ln -sfnv ${PWD}/claude/settings.json ${claude_config_path}/settings.json

codex_config_path=${HOME}/.codex
if [ ! -d "$codex_config_path" ]; then
  mkdir -p "$codex_config_path"
fi
ln -sfnv ${agents_md} ${codex_config_path}/AGENTS.md

# Claude plugins (skills-dir auto-load)
if [ ! -d "${claude_config_path}/skills" ]; then
  mkdir -p "${claude_config_path}/skills"
fi
ln -sfnv ${PWD}/config ${claude_config_path}/skills/tokizuoh-skills
