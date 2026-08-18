#!/usr/bin/env bash
#
# setup-gnome-keyring-sddm-sway.sh
#
# Installs gnome-keyring + seahorse and configures PAM (SDDM) so the
# login keyring auto-starts and auto-unlocks using your login password,
# for use with Sway + VS Code (or any app needing the Secret Service).
#
# Safe to re-run: checks for existing lines before adding, and backs up
# any file it edits.

set -euo pipefail

PAM_FILE="/etc/pam.d/sddm"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

require_root_for() {
    if [[ $EUID -ne 0 ]]; then
        echo "This step needs root — re-running with sudo: $*"
        sudo "$@"
    else
        "$@"
    fi
}

echo "==> 1. Installing gnome-keyring and seahorse"
require_root_for dnf install -y gnome-keyring seahorse

if [[ ! -f "$PAM_FILE" ]]; then
    echo "ERROR: $PAM_FILE does not exist."
    echo "You may not be on SDDM, or its PAM config lives elsewhere."
    echo "Run 'cat /etc/sddm.conf' or 'ls /etc/sddm.conf.d/' to check your setup, then"
    echo "point this script at the right /etc/pam.d/<file> and re-run."
    exit 1
fi

echo "==> 2. Backing up $PAM_FILE to ${PAM_FILE}.bak-${TIMESTAMP}"
sudo cp "$PAM_FILE" "${PAM_FILE}.bak-${TIMESTAMP}"

AUTH_LINE="auth       optional     pam_gnome_keyring.so"
SESSION_LINE="session    optional     pam_gnome_keyring.so auto_start"

echo "==> 3. Adding PAM auth line (unlocks keyring with login password)"
if grep -qE "^auth\s.*pam_gnome_keyring\.so" "$PAM_FILE"; then
    echo "    auth line already present, skipping"
else
    # Insert after the first 'auth ... include <something-auth>' line
    # (Fedora's sddm file uses password-auth, others use system-auth).
    # Fall back to inserting at the top of the file if no such line exists.
    if grep -qE "^auth\s+(include|substack)\s+(password|system)-auth" "$PAM_FILE"; then
        sudo sed -i "0,/^auth\s\+\(include\|substack\)\s\+\(password\|system\)-auth/{/^auth\s\+\(include\|substack\)\s\+\(password\|system\)-auth/a ${AUTH_LINE}
        }" "$PAM_FILE"
    else
        sudo sed -i "1i ${AUTH_LINE}" "$PAM_FILE"
    fi
    echo "    added"
fi

echo "==> 4. Adding PAM session line (starts gnome-keyring-daemon)"
if grep -qE "^session\s.*pam_gnome_keyring\.so" "$PAM_FILE"; then
    echo "    session line already present, skipping"
else
    if grep -qE "^session\s+(include|substack)\s+(password|system)-auth" "$PAM_FILE"; then
        sudo sed -i "0,/^session\s\+\(include\|substack\)\s\+\(password\|system\)-auth/{/^session\s\+\(include\|substack\)\s\+\(password\|system\)-auth/a ${SESSION_LINE}
        }" "$PAM_FILE"
    else
        echo "${SESSION_LINE}" | sudo tee -a "$PAM_FILE" > /dev/null
    fi
    echo "    added"
fi

echo "==> 5. Resulting $PAM_FILE:"
echo "-----------------------------------------------"
cat "$PAM_FILE"
echo "-----------------------------------------------"

echo "==> 6. Checking for an existing login keyring"
LOGIN_KEYRING="$HOME/.local/share/keyrings/login.keyring"
if [[ -f "$LOGIN_KEYRING" ]]; then
    cat <<EOF

NOTE: You already have a login keyring at:
    $LOGIN_KEYRING

Auto-unlock only works if its password matches your account login
password. Options:
  a) Open 'seahorse', right-click the "Login" keyring -> Change Password,
     and set it to match your login password.
  b) Or, if you don't mind losing saved secrets, back it up and remove it
     so it gets recreated fresh on next login:
       mv "$LOGIN_KEYRING" "$LOGIN_KEYRING.bak-${TIMESTAMP}"

EOF
else
    echo "    No existing login keyring found — one will be created and"
    echo "    auto-password-matched on your next login. Nothing to do."
fi

echo "==> 7. Sway config check"
SWAY_CONFIG="$HOME/.config/sway/config"
if [[ -f "$SWAY_CONFIG" ]] && grep -q "gnome-keyring-daemon --start" "$SWAY_CONFIG"; then
    cat <<EOF

NOTE: Found a manual 'exec gnome-keyring-daemon --start ...' line in:
    $SWAY_CONFIG

This is no longer needed since PAM's auto_start now launches the daemon
before Sway even starts. It's harmless to leave (gnome-keyring-daemon
handles being invoked twice gracefully), but you can remove that line
if you want a cleaner config.
EOF
else
    echo "    No conflicting exec line found in Sway config — good."
fi

cat <<EOF

==> Done.

Next steps:
  1. Log out completely (not just lock the screen).
  2. Log back in via SDDM as normal.
  3. Run 'seahorse' and confirm the "Login" keyring shows unlocked
     (no padlock icon).
  4. Launch VS Code from that same session and confirm it no longer
     prompts for a keyring password.

If VS Code still prompts, check:
  echo \$SSH_AUTH_SOCK
  loginctl show-session \$XDG_SESSION_ID -p Type
to confirm the session picked up the keyring's D-Bus environment.
EOF
