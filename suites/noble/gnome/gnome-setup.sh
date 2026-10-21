#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
    ubuntu-desktop-minimal \
    gnome-shell-ubuntu-extensions gnome-shell-extensions \
    gnome-terminal dbus dbus-x11 dconf-cli gsettings-desktop-schemas \
    xauth x11-utils x11-xserver-utils mesa-utils mesa-utils-extra \
    libgl1-mesa-dri libglx-mesa0 libegl1 libgles2 libgbm1 libdrm2 \
    locales fonts-ubuntu fonts-noto-color-emoji

locale-gen en_US.UTF-8 || true
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 || true

mkdir -p /etc/profile.d
cat > /etc/profile.d/gnome-termux-x11.sh <<'PROFILE'
export DISPLAY=:0
export XDG_CURRENT_DIR=GNOME
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=gnome
export DESKTOP_SESSION=gnome
export GALLIUM_DRIVER=virpipe
export GSK_RENDERER=cairo
PROFILE
chmod 0644 /etc/profile.d/gnome-termux-x11.sh
