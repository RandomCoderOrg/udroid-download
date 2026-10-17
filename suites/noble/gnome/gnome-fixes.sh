#!/usr/bin/env bash
set -e

# Prevent activation of systemd logind inside a non-systemd PRoot environment.
mkdir -p /root/login1-disabled
if [[ -f /usr/share/dbus-1/system-services/org.freedesktop.login1.service ]]; then
  mv /usr/share/dbus-1/system-services/org.freedesktop.login1.service \
     /root/login1-disabled/org.freedesktop.login1.service
fi

mkdir -p /etc/profile.d /etc/dconf/profile /etc/dconf/db/local.d
cat > /etc/profile.d/gtk-cairo.sh <<'PROFILE'
export GSK_RENDERER=cairo
PROFILE
chmod 0644 /etc/profile.d/gtk-cairo.sh

cat > /etc/dconf/profile/user <<'PROFILE'
user-db:user
system-db:local
PROFILE

if command -v dconf >/dev/null 2>&1; then
  dconf update || true
fi

cat > /usr/local/bin/udroid-gnome-x11 <<'LAUNCH'
#!/usr/bin/env bash
set -e
export DISPLAY=:0
export XDG_CURRENT_DIR=GNOME
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=gnome
export DESKTOP_SESSION=gnome
export GALLIUM_DRIVER=virpipe
export GSK_RENDERER=cairo
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
unset DBUS_SESSION_BUS_ADDRESS DBUS_SYSTEM_BUS_ADDRESS
service dbus start >/dev/null 2>&1 || true
if command -v dbus-run-session >/dev/null 2>&1; then
  exec dbus-run-session -- gnome-shell --x11 --sm-disable
fi
exec gnome-shell --x11 --sm-disable
LAUNCH
chmod 0755 /usr/local/bin/udroid-gnome-x11

cat > /root/start-gnome.sh <<'LAUNCH'
#!/usr/bin/env bash
exec /usr/local/bin/udroid-gnome-x11 "$@"
LAUNCH
chmod 0755 /root/start-gnome.sh
