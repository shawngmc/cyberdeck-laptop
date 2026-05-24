#!/bin/bash

# Install Font
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/RobotoMono.zip" -o RobotoMono.zip
unzip RobotoMono.zip
rm RobotoMono.zip
fc-cache -f

