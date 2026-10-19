#!/usr/bin/env bash
set -e

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

# Clean stale seat records so GNOME doesn't hang waiting for logind
if ! pgrep -x systemd-logind >/dev/null 2>&1; then
  rm -rf -- /run/systemd/seats
fi

# Prepare the system bus for non-systemd PRoot environments.
mkdir -p /run/dbus
dbus-uuidgen --ensure=/etc/machine-id >/dev/null 2>&1 || true

# Try the normal service first.
service dbus start >/dev/null 2>&1 || true

# Recover if the system bus is stale or unresponsive.
if ! dbus-send --system --print-reply \
  --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames \
  >/dev/null 2>&1; then
  if [ -s /run/dbus/pid ]; then
    dbus_pid="$(cat /run/dbus/pid)"
    case "$dbus_pid" in
      ''|*[!0-9]*) ;;
      *) kill "$dbus_pid" 2>/dev/null || true ;;
    esac
  fi

  rm -f /run/dbus/system_bus_socket /run/dbus/pid
  dbus-daemon --system --fork --nopidfile --nosyslog
fi

# Verify recovery before starting GNOME.
dbus-send --system --print-reply \
  --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames \
  >/dev/null

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
