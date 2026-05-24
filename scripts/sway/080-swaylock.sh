#!/bin/bash

i# Swaylock
SWAYLOCK_CONFIG="$HOME/.config/swaylock/config"
SWAYLOCK_DIR="$(dirname "$SWAYLOCK_CONFIG")"
SYSTEM_CONFIG="/etc/swaylock/config"
WALLPAPER="$HOME/.config/sway/neon_poly_tiger.jpg"
 
# Create directory if needed
mkdir -p "$SWAYLOCK_DIR"
 
# Copy system config if user config doesn't exist
if [[ ! -f "$SWAYLOCK_CONFIG" ]]; then
    if [[ -f "$SYSTEM_CONFIG" ]]; then
        echo "Copying system config to $SWAYLOCK_CONFIG"
        cp "$SYSTEM_CONFIG" "$SWAYLOCK_CONFIG"
    else
        echo "No system config found — creating default config at $SWAYLOCK_CONFIG"
        touch "$SWAYLOCK_CONFIG"
    fi
else
    echo "Config already exists at $SWAYLOCK_CONFIG — leaving in place"
fi
 
# Helper: set or replace a key in the config
set_key() {
    local key="$1"
    local value="$2"
    if grep -qE "^#?[[:space:]]*${key}=" "$SWAYLOCK_CONFIG" 2>/dev/null; then
        sed -i "s|^#\?[[:space:]]*${key}=.*|${key}=${value}|" "$SWAYLOCK_CONFIG"
    else
        echo "${key}=${value}" >> "$SWAYLOCK_CONFIG"
    fi
}
 
# --- Wallpaper ---
set_key "image"           "$WALLPAPER"
set_key "scaling"         "fill"
 
# --- Font ---
set_key "font"            "RobotoMono Nerd Font"
 
# --- Ring (neon black/blue-teal theme) ---
# Normal state
set_key "color"           "000000ff"          # background fill when no image
set_key "ring-color"      "000000ff"          # ring base: black
set_key "key-hl-color"    "00f5ffff"          # neon teal keypress highlight
set_key "line-color"      "00000000"          # line between ring layers: transparent
set_key "inside-color"    "00000088"          # inside fill: semi-transparent black
set_key "separator-color" "00000000"          # separator: transparent
 
# Verifying state (typing)
set_key "ring-ver-color"  "00e5ffcc"          # neon teal/blue while verifying
set_key "line-ver-color"  "00000000"
set_key "inside-ver-color" "00000088"
 
# Wrong password
set_key "ring-wrong-color" "ff00aaff"         # neon pink on wrong
set_key "line-wrong-color" "00000000"
set_key "inside-wrong-color" "1a001088"       # dark pink-tinted inside
 
# Cleared state
set_key "ring-clear-color"  "00f5ff88"
set_key "line-clear-color"  "00000000"
set_key "inside-clear-color" "00000088"
 
# --- Text ---
set_key "text-color"          "00f5ffff"      # neon teal text
set_key "text-ver-color"      "00e5ffff"
set_key "text-wrong-color"    "ff00aaff"      # neon pink for wrong
set_key "text-clear-color"    "00f5ffcc"
set_key "bs-hl-color"         "ff00aaff"      # neon pink backspace highlight


