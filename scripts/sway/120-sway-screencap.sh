#!/bin/bash

cat <<'EOF' >> ~/.config/sway/config
# Grab box to clipboard
bindsym $mod+Shift+S exec grim -g "$(slurp)" - | wl-copy
# Capture box to Pictures folder
bindsym $mod+Alt+Shift+S exec grim -g "$(slurp)" ~/Pictures/$(date +'%Y-%m-%d-%H%M%S.png')
# Capture entire screen to Pictures folder
bindsym $mod+Ctrl+Shift+S exec grim ~/Pictures/$(date +'%Y-%m-%d-%H%M%S.png')
EOF
