#!/usr/bin/env bash
# Run inside a Noble rootfs after its theme assets and XFCE config are copied.
set -euo pipefail

for asset in \
    /usr/share/themes/udroid-xfsmooth-light/gtk-3.0/gtk.css \
    /usr/share/icons/udroid-tela-black/index.theme; do
    if [ ! -f "$asset" ]; then
        echo "Missing $asset. Copy the bundle from suites/noble/xfce4/assets first." >&2
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/xfce4-setup.sh"
bash "$SCRIPT_DIR/xfce4-extra.sh"
bash "$SCRIPT_DIR/xfce4-fixes.sh"
bash "$SCRIPT_DIR/xfce4-cleanup.sh"
echo "XFCE setup complete. Start it with: /usr/local/bin/udroid-xfce4-x11"
