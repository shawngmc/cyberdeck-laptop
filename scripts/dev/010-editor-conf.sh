#!/bin/bash

cat <<EOF >> ~/.bashrc
# Set default editor
export EDITOR="nvim"
export VISUAL="nvim"
git config --global core.editor nvim
alias vi='nvim'
alias vim='nvim'
EOF
