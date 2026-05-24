#!/bin/bash

# Install Starship
brew install starship
echo '' >> ~/.bashrc
echo '# Starship init' >> ~/.bashrc
echo 'eval "$(starship init bash)"' >> ~/.bashrc
source ~/.bashrc
