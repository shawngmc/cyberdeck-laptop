#/bin/bash

# Copy default
mkdir -pv ~/.config/sway
cp /etc/sway/config ~/.config/sway/config

# Add floating UI look
cat <<EOF >> ~/.config/sway/config
# Gaps for that floating UI look
gaps inner 6
gaps outer 4
# Sharp borders
default_border pixel 2
# Color scheme: class         border    bg        text      indicator  child_border
client.focused                #00FFFF   #0A0A0F   #00FFFF   #FF00FF    #00FFFF
client.focused_inactive       #1A1A2E   #0A0A0F   #444466   #1A1A2E    #1A1A2E
client.unfocused              #0D0D1A   #0A0A0F   #333355   #0D0D1A    #0D0D1A
client.urgent                 #FF00FF   #0A0A0F   #FF00FF   #FF00FF    #FF00FF
# Custom keybinds
bindsym $mod+l exec swaylock
EOF

# Disable ijkl keybinds
sed -i 's/^\(\s*bindsym \$mod+\$\(left\|right\|up\|down\)\)/    #\1/' ~/.config/sway/config
sed -i 's/^\(\s*bindsym \$mod+Shift+\$\(left\|right\|up\|down\)\)/    #\1/' ~/.config/sway/config

