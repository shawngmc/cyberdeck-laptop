#!/bin/bash

# Install Nemo File Manager
sudo dnf install nemo nemo-fileroller adw-gtk3-theme -y

# Download CyberHack GTK Theme
mkdir -p ~/.themes
git clone https://git.disroot.org/eudaimon/CyberHack.git ~/.themes/CyberHack

# Tell GTK to load theme
mkdir -pv ~/.config/gtk-3.0/
cat <<EOF >>~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=CyberHack
gtk-application-prefer-dark-theme=1
EOF

# Have sway alway set the GTK theme
cat <<EOF >> ~/.config/sway/config
exec_always gsettings set org.gnome.desktop.interface gtk-theme 'CyberHack'
exec_always gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
EOF

# Force GTK theme in bashrc
cat <<EOF >> ~/.bashrc
# Force GTK Theme
export GTK_THEME=CyberHack
EOF

# Remove thunar file manager
sudo dnf remofe Thunar
