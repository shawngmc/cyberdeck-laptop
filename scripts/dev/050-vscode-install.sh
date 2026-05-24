#!/bin/bash

# 1. Import Microsoft's GPG key
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

# 2. Add the VS Code repository
sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# 3. Install
dnf check-update && sudo dnf install code
