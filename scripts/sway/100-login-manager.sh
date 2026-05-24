#!/bin/bash

# Login Manager SDDM
# Test Command
# swaylock -f
# (exit with Mod-Shift-Q)
# TODO: This is only background - add font, colors, etc.
# Probably just clone the theme
# Then expose font and colors as config. vars

# Set config for theme
sudo mkdir -p /etc/sddm.conf.d/
cat <<EOF | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
[Theme]
Current=03-sway-fedora
EOF

# Copy background
mkdir -pv /usr/share/sddm/themes/03-sway-fedora/
sudo cp ~/.config/sway/neon_poly_tiger.jpg /usr/share/sddm/themes/03-sway-fedora/neon_poly_tiger.jpg

# Add BG to theme
cat <<EOF | sudo tee /usr/share/sddm/themes/03-sway-fedora/theme.conf.user > /dev/null
[General]
background=/usr/share/sddm/themes/03-sway-fedora/neon_poly_tiger.jpg
EOF
