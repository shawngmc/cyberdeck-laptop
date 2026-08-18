#!/usr/bin/env bash
#
# setup-gnome-keyring-sddm-sway.sh
#
# Installs gnome-keyring + seahorse + gcr (for gcr-ssh-agent — SSH
# agent support was removed from gnome-keyring-daemon in v46 and now
# lives here) and configures:
#   1. PAM (SDDM) so the login keyring auto-starts and auto-unlocks
#      using your login password.
#   2. gcr-ssh-agent.socket (systemd --user), which provides the
#      actual SSH agent.
#   3. A systemd environment.d file so SSH_AUTH_SOCK (pointing at
#      gcr-ssh-agent's socket) and GNOME_KEYRING_CONTROL are part of
#      your session environment before Sway starts, so Sway and
#      everything it spawns inherit them.
#   4. VS Code's argv.json, so it uses gnome-libsecret instead of
#      trying (and failing) to auto-detect a keyring backend on Sway.
#
# Safe to re-run: checks existing content before changing anything,
# and backs up any file it edits.

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

echo "==> 1. Installing gnome-keyring, seahorse, and gcr (gcr-ssh-agent)"
require_root_for dnf install -y gnome-keyring seahorse gcr

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
    # Fedora's sddm file uses password-auth; other distros use system-auth.
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

echo "==> 7. Enabling gcr-ssh-agent.socket (provides the actual SSH agent)"
systemctl --user daemon-reload
if systemctl --user is-enabled gcr-ssh-agent.socket &>/dev/null; then
    echo "    already enabled"
else
    systemctl --user enable --now gcr-ssh-agent.socket
    echo "    enabled and started"
fi

echo "==> 8. Writing environment.d file for the keyring env"
ENV_D_DIR="$HOME/.config/environment.d"
ENV_D_FILE="$ENV_D_DIR/60-gnome-keyring.conf"
mkdir -p "$ENV_D_DIR"

RUNTIME_DIR="/run/user/$(id -u)"

if [[ -f "$ENV_D_FILE" ]] && grep -q "^SSH_AUTH_SOCK=${RUNTIME_DIR}/gcr/ssh$" "$ENV_D_FILE"; then
    echo "    $ENV_D_FILE already correct, skipping"
else
    cat > "$ENV_D_FILE" <<EOF
# Added by setup-gnome-keyring-sddm-sway.sh
# gcr-ssh-agent's and gnome-keyring's socket paths are deterministic,
# so they're declared here literally rather than captured dynamically.
# pam_systemd reads this file at login and injects these into the
# session environment before Sway is exec'd, so Sway and everything
# it spawns inherit them.
SSH_AUTH_SOCK=${RUNTIME_DIR}/gcr/ssh
GNOME_KEYRING_CONTROL=${RUNTIME_DIR}/keyring
EOF
    echo "    Wrote $ENV_D_FILE"
fi

echo "==> 9. Configuring VS Code to use gnome-libsecret for its keyring"
CODE_DIRS=(
    "$HOME/.config/Code"
    "$HOME/.config/Code - Insiders"
    "$HOME/.config/VSCodium"
    "$HOME/.config/Code - OSS"
)

FOUND_ANY=0
for dir in "${CODE_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    FOUND_ANY=1
    ARGV_JSON="$dir/argv.json"
    echo "    Found $dir"

    if [[ -f "$ARGV_JSON" ]]; then
        cp "$ARGV_JSON" "${ARGV_JSON}.bak-${TIMESTAMP}"
    fi

    python3 - "$ARGV_JSON" <<'PYEOF'
import re
import sys
import pathlib

path = pathlib.Path(sys.argv[1])
KEY = "password-store"
VALUE = "gnome-libsecret"

if not path.exists():
    path.write_text('{\n    "%s": "%s"\n}\n' % (KEY, VALUE))
    print("    Created %s" % path)
    sys.exit(0)

text = path.read_text()

# Look for an ACTIVE (non-commented) password-store line.
m = re.search(
    r'^(?!\s*//)\s*"%s"\s*:\s*"([^"]*)"\s*,?\s*$' % re.escape(KEY),
    text, re.MULTILINE,
)
if m:
    if m.group(1) == VALUE:
        print("    %s already set to %s, skipping" % (KEY, VALUE))
        sys.exit(0)
    line = m.group(0)
    new_line = re.sub(r'"([^"]*)"(\s*,?\s*)$', '"%s"\\2' % VALUE, line)
    text = text[:m.start()] + new_line + text[m.end():]
    path.write_text(text)
    print("    Updated existing %s value" % KEY)
    sys.exit(0)

# No active key — insert one just before the final closing brace,
# preserving comments/formatting already in the file.
close_idx = text.rstrip().rfind('}')
if close_idx == -1:
    print("    WARNING: couldn't find a closing brace in %s" % path)
    print('    Add this manually: "%s": "%s"' % (KEY, VALUE))
    sys.exit(1)

before, after = text[:close_idx], text[close_idx:]
lines = before.splitlines(keepends=True)

last_idx = None
for i in range(len(lines) - 1, -1, -1):
    stripped = lines[i].strip()
    if stripped in ('', '{') or stripped.startswith('//'):
        continue
    last_idx = i
    break

if last_idx is not None:
    stripped = lines[last_idx].rstrip('\n')
    if not stripped.rstrip().endswith(','):
        newline = '\n' if lines[last_idx].endswith('\n') else ''
        lines[last_idx] = stripped.rstrip() + ',' + newline

new_text = ''.join(lines) + '    "%s": "%s"\n' % (KEY, VALUE) + after
path.write_text(new_text)
print("    Added %s to %s" % (KEY, path))
PYEOF
done

if [[ "$FOUND_ANY" -eq 0 ]]; then
    echo "    No VS Code config directory found under ~/.config."
    echo "    If VS Code is installed, add this manually via the Command"
    echo "    Palette -> 'Preferences: Configure Runtime Arguments':"
    echo "      \"password-store\": \"gnome-libsecret\""
fi

cat <<EOF

==> Done.

Next steps:
  1. Log out completely (not just lock the screen — environment.d is
     only read at login).
  2. Log back in via SDDM as normal.
  3. Run 'seahorse' and confirm the "Login" keyring shows unlocked
     (no padlock icon).
  4. Open a terminal and check:
       echo \$SSH_AUTH_SOCK
       systemctl --user status gcr-ssh-agent.socket
  5. Run 'ssh-add ~/.ssh/id_ed25519' (or whichever key you use) once.
     You'll get one GUI passphrase prompt — check "Automatically
     unlock this key whenever I'm logged in" so it's cached in your
     (now auto-unlocked) login keyring. After this one-time step,
     git push and VS Code should stop asking for the passphrase.
  6. Fully quit VS Code (all windows — argv.json is only read at full
     process start, not on 'Reload Window'), then relaunch it and
     confirm it no longer prompts about a missing keyring.

If SSH_AUTH_SOCK is still empty after a fresh login:
  systemctl --user show-environment | grep -i keyring
  systemctl --user status gcr-ssh-agent.socket
  ls -la \$XDG_RUNTIME_DIR/gcr/
EOF
