#!/usr/bin/env bash
# Installs/updates itsjfx/sway-alttab-gui using the gh CLI and wires up
# the Alt-Tab keybind in sway config.
set -euo pipefail

REPO="itsjfx/sway-alttab-gui"
BIN_DIR="$HOME/.local/bin"
SWAY_CONFIG="${SWAY_CONFIG:-$HOME/.config/sway/config}"
GTK4_CSS="${GTK4_CSS:-$HOME/.config/gtk-4.0/gtk.css}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found — install it first (dnf install gh) or use the curl-based script." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "==> Note: gh isn't authenticated. Public-repo downloads still work, but you may" >&2
  echo "    hit unauthenticated rate limits. Run 'gh auth login' if this fails." >&2
fi

echo "==> Checking runtime deps (gtk4, gtk4-layer-shell)..."
if ! rpm -q gtk4 gtk4-layer-shell >/dev/null 2>&1; then
  echo "    Missing on this system — installing via dnf (sudo required)."
  sudo dnf install -y gtk4 gtk4-layer-shell
fi

mkdir -p "$BIN_DIR"

echo "==> Fetching latest release binary from $REPO..."
DL_DIR="$TMP_DIR/assets"
mkdir -p "$DL_DIR"
ASSET_NAME="sway-alttab-gui-linux-amd64"
if ! gh release download -R "$REPO" -p "$ASSET_NAME" -D "$DL_DIR"; then
  echo "Couldn't download $ASSET_NAME from the latest release of $REPO." >&2
  echo "Check https://github.com/$REPO/releases for the current asset name." >&2
  exit 1
fi

install -m 755 "$DL_DIR/$ASSET_NAME" "$BIN_DIR/sway-alttab-gui"

echo "==> Installed to $BIN_DIR/sway-alttab-gui"
"$BIN_DIR/sway-alttab-gui" --version 2>/dev/null || true

echo "==> Staging GTK4 theme CSS ($GTK4_CSS)..."
mkdir -p "$(dirname "$GTK4_CSS")"
touch "$GTK4_CSS"

CSS_MARKER="/* sway-alttab-gui (managed by install-sway-alttab-gui-gh.sh) */"
if grep -qF "$CSS_MARKER" "$GTK4_CSS"; then
  echo "    CSS block already present — leaving it as-is."
else
  cat >> "$GTK4_CSS" <<'EOF'

/* sway-alttab-gui (managed by install-sway-alttab-gui-gh.sh) */
@define-color neon-bg #05050f;
@define-color neon-bg-alt #0a0a1e;
@define-color neon-cyan #00ffff;
@define-color neon-mint #00ffcc;
@define-color neon-magenta #ff00ff;
@define-color neon-border #1a1a3a;

window {
  background-color: @neon-bg;
  border: 1px solid @neon-cyan;
}

box.horizontal {
  background-color: transparent;
  padding: 6px;
}

box.vertical {
  background-color: @neon-bg-alt;
  border: 1px solid @neon-border;
  padding: 6px;
  margin: 2px;
}

box.vertical label {
  color: @neon-mint;
  font-family: "RobotoMono Nerd Font";
  font-size: 13px;
}

box.selected {
  background-color: @neon-bg;
  border: 1px solid @neon-magenta;
}

box.selected label {
  color: @neon-magenta;
}



EOF
  echo "    Added neon theme block."
  echo "    Note: applies to ALL GTK4 apps on this system, not just sway-alttab-gui."
fi

echo "==> Wiring up sway config ($SWAY_CONFIG)..."
if [[ ! -f "$SWAY_CONFIG" ]]; then
  echo "    Couldn't find $SWAY_CONFIG — set SWAY_CONFIG=/path/to/config and rerun." >&2
  exit 1
fi

MARKER="# sway-alttab-gui (managed by install-sway-alttab-gui-gh.sh)"
if grep -qF "$MARKER" "$SWAY_CONFIG"; then
  echo "    Config block already present — leaving it as-is."
else
  cat >> "$SWAY_CONFIG" <<EOF

$MARKER
exec --no-startup-id $BIN_DIR/sway-alttab-gui daemon
bindsym Mod1+Tab exec $BIN_DIR/sway-alttab-gui show
bindsym Mod1+Shift+Tab exec $BIN_DIR/sway-alttab-gui show --reverse
EOF
  echo "    Added exec + Alt+Tab / Alt+Shift+Tab binds."
fi

echo "==> Reloading sway..."
swaymsg reload

echo "==> Ensuring the daemon is running..."
if pgrep -f "$BIN_DIR/sway-alttab-gui daemon" >/dev/null 2>&1; then
  echo "    Already running. (Restart it manually if you just edited the CSS —"
  echo "    GTK apps only re-read gtk.css on launch.)"
else
  setsid "$BIN_DIR/sway-alttab-gui" daemon >/dev/null 2>&1 &
  disown
  echo "    Started."
fi

echo "Done."
