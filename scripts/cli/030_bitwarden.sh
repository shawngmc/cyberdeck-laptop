#!/bin/bash

# Set up bitwarden
brew install bitwarden-cli
bw config server https://bitwarden.hitoma.com
bw login
echo '' >> ~/.bashrc
echo '# Bitwarden Alias' >> ~/.bashrc
echo "alias bw-unlock='export BW_SESSION=\$(bw unlock --raw)'" >> ~/.bashrc
source ~/.bashrc
export BW_SESSION=$(bw unlock --raw)
