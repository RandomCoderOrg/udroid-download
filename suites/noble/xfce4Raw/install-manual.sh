#!/usr/bin/env bash
# Install XFCE4 and upstream themes inside a Noble root filesystem.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root inside the target root filesystem." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in \
    xfce4-setup.sh \
    xfce4-extra.sh \
    xfce4-themes.sh \
    xfce4-fixes.sh \
    xfce4-cleanup.sh
do
    bash "$SCRIPT_DIR/$script"
done

echo "XFCE setup complete. Start with: /usr/local/bin/udroid-xfce4-x11"
