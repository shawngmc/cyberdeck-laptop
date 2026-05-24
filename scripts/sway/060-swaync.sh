#!/bin/bash

# Install swaync
sudo dnf install swaync

# Sey swaync as notifier
cat <<EOF >> ~/.config/sway/config
exec swaync
bindsym \$mod+Shift+n exec swaync-client -t
EOF

# Apply style
mkdir -pv ~/.config/swaync/
cp swaync.css ~/.config/swaync/style.css
