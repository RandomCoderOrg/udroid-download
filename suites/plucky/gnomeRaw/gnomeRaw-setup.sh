#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

# Prevent package maintainer scripts from trying to start system services
# during image construction. Services are started explicitly at runtime.
mkdir -p /usr/sbin
cat > /usr/sbin/policy-rc.d <<'POLICY'
#!/bin/sh
exit 101
POLICY
chmod 0755 /usr/sbin/policy-rc.d

apt-get update
apt-get install -y \
  gnome-core gnome-shell gnome-control-center nautilus gnome-terminal \
  gnome-shell-extensions gnome-shell-extension-ubuntu-dock \
  dbus dbus-bin dbus-x11 dconf-cli xorg xauth x11-utils x11-xserver-utils \
  mesa-utils libgl1-mesa-dri libglx-mesa0 libegl1 libgles2 libgbm1 libdrm2 \
  locales network-manager sudo nano wget curl git ca-certificates \
  fonts-ubuntu fonts-noto-color-emoji

locale-gen en_US.UTF-8 || true
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 || true

mkdir -p /etc/profile.d
cat > /etc/profile.d/gnome-termux-x11.sh <<'PROFILE'
# Defaults for GNOME running against a Termux:X11 display.
export DISPLAY="${DISPLAY:-:0}"
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=gnome
export DESKTOP_SESSION=gnome

# Use Mesa's CPU renderer. VirGL/KGSL overrides are handled by the launcher.
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export GSK_RENDERER=cairo
PROFILE
chmod 0644 /etc/profile.d/gnome-termux-x11.sh
