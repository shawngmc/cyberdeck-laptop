#!/bin/bash

# Set up aerc for gmail
brew install aerc w3m
mkdir -pv ~/.config/aerc
cp /home/linuxbrew/.linuxbrew/share/aerc/binds.conf ~/.config/aerc/binds.conf
cp /home/linuxbrew/.linuxbrew/share/aerc/aerc.conf ~/.config/aerc/aerc.conf
sed -i 's|^text/html=! html$|text/html=/home/linuxbrew/.linuxbrew/bin/w3m -T text/html -o display_link_number=1|' ~/.config/aerc/aerc.conf
sed -i 's|^#alternatives=text/plain,text/html$|alternatives=text/html,text/plain|' ~/.config/aerc/aerc.conf
echo <<EOF > ~/.config/aerc/accounts.conf
[Gmail]
source        = imaps://shawngmc@gmail.com@imap.gmail.com:993
outgoing      = smtps+plain://shawngmc@gmail.com@smtp.gmail.com:465
from          = Shawn McNaughton <shawngmc@gmail.com>
default = INBOX
folders-sort = INBOX
postpone = [Gmail]/Drafts
cache-headers = true
source-cred-cmd   = bw get password 79b829cb-8236-4c14-a7df-d3d1344759c8
outgoing-cred-cmd = bw get password 79b829cb-8236-4c14-a7df-d3d1344759c8
carddav-source = https://shawngmc@gmail.com@www.googleapis.com/carddav/v1/principals/shawngmc@gmail.com/lists/default
carddav-source-cred-cmd = bw get password 79b829cb-8236-4c14-a7df-d3d1344759c8
address-book-cmd = carddav-query %s
EOF
