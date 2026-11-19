#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

# Suppress service startup only while packages are installed in the image.
# Restore any pre-existing policy-rc.d (or remove ours) even if APT fails.
policy_file=/usr/sbin/policy-rc.d
policy_backup=/tmp/udroid-policy-rc.d.backup
had_policy=false
if [[ -e "$policy_file" || -L "$policy_file" ]]; then
  cp -a "$policy_file" "$policy_backup"
  had_policy=true
else
  rm -f "$policy_backup"
fi

restore_policy_rc_d() {
  if [[ "$had_policy" == true ]]; then
    rm -f "$policy_file"
    mv -f "$policy_backup" "$policy_file"
  else
    rm -f "$policy_file" "$policy_backup"
  fi
}
trap restore_policy_rc_d EXIT

mkdir -p /usr/sbin
cat > "$policy_file" <<'POLICY'
#!/bin/sh
exit 101
POLICY
chmod 0755 "$policy_file"

apt-get update
apt-get install -y \
  gnome-core gnome-shell gnome-control-center nautilus gnome-terminal \
  gnome-shell-extensions gnome-shell-extension-ubuntu-dock \
  dbus dbus-bin dbus-x11 dconf-cli xorg xauth x11-utils x11-xserver-utils \
  mesa-utils libgl1-mesa-dri libglx-mesa0 libegl1 libgles2 libgbm1 libdrm2 \
  locales network-manager sudo nano wget curl git ca-certificates \
  fonts-ubuntu fonts-noto-color-emoji

restore_policy_rc_d
trap - EXIT

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
