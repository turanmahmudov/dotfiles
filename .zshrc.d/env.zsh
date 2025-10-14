#!/bin/zsh

export EDITOR='nvim'
export WORKSPACES="$HOME/Workspaces"

export COMPOSER_HOME=$(composer config --global home --no-plugins)
export COMPOSER_CACHE_DIR=$(composer config --global cache-dir --no-plugins)
