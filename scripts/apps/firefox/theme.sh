#!/bin/bash

# Firefox
# TODO: Enable userchrome in about:config
# toolkit.legacyUserProfileCustomizations.stylesheets = true
# browser.tabs.inTitlebar = 0
PROFILE_DIR="$HOME/.config/mozilla/firefox/$(grep Path ~/.config/mozilla/firefox/profiles.ini | grep default-release | cut -d= -f2)"
mkdir -pv ${PROFILE_DIR}/chrome/
cp ./userChrome.css ${PROFILE_DIR}/chrome/userChrome.css
