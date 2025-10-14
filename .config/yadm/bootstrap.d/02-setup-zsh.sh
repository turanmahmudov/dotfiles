#!/bin/sh
# Secrets and Environment

ANTIDOTE_DIR="$HOME/.antidote"
if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "Installing Antidote (Zsh Plugin Manager)..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

# Setup Secrets from Template
if [ -f "${ZDOTDIR:-$HOME}/.zshrc.d/secrets.zsh.dist" ] && [ ! -f "${ZDOTDIR:-$HOME}/.zshrc.d/secrets.zsh" ]; then
    cp "${ZDOTDIR:-$HOME}/.zshrc.d/secrets.zsh.dist" "${ZDOTDIR:-$HOME}/.zshrc.d/secrets.zsh"
fi

