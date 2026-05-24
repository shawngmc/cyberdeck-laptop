#!/bin/bash

# Install fuzzel
sudo dnf install fuzzel

# Set fuzzle as default
sed -i 's/^set \$menu/# set \$menu/; /^# set \$menu/a set \$menu fuzzel' ~/.config/sway/config

# Copy config
cp ./fuzzel.ini ~/.config/fuzzel/fuzzel.ini
