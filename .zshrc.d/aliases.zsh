#!/bin/zsh

alias _=sudo
alias l=ls
alias g=git

alias vim=nvim
alias vi=nvim
alias v=nvim

alias ll='ls -lh'
alias la='ls -lAh'
alias ldot='ls -ld .*'

alias quit='exit'
alias cd..='cd ..'

alias fd='find . -type d -name'
alias ff='find . -type f -name'

# url encode/decode
alias urldecode='python3 -c "import sys, urllib.parse as ul; \
    print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; \
    print (ul.quote_plus(sys.argv[1]))"'

# misc
alias zshrc='${EDITOR:-nvim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zdot='cd ${ZDOTDIR:-~}'

# tmux
alias tnew='tmux new -s'
alias tatt='tmux attach -t'
alias tkill='tmux kill-session -t'
alias tlist='tmux list-sessions'

alias npm-ls='npm list -g --depth 0'

alias claude='CLAUDE_CODE_DISABLE_KITTY_KEYBOARD=1 env -u ANTHROPIC_BASE_URL claude'
