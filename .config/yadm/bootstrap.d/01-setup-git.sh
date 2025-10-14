#!/bin/sh
# Git Identity & Tool Integration

# Symlink .git for Lazygit/Neovim
if [ ! -L "$HOME/.git" ]; then
    ln -s "$HOME/.local/share/yadm/repo.git" "$HOME/.git"
fi

# Prompt for Git info if missing
if [ -z "$(git config --global user.email)" ]; then
    printf "Enter Git Name: " && read -r GIT_NAME
    printf "Enter Git Email: " && read -r GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    echo "Git identity set to: $GIT_NAME <$GIT_EMAIL>"
fi
git config --global url.ssh://git@github.com/.insteadOf https://github.com/
