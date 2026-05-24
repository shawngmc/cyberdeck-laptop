#!/bin/bash

# Set up FZF
brew install fzf
echo '' >> ~/.bashrc
echo '# FZF init' >> ~/.bashrc
echo 'source <(fzf --bash)' >> ~/.bashrc
source <(fzf --bash)
