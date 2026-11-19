#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p /etc/profile.d /etc/dconf/profile /etc/dconf/db/local.d
cat > /etc/dconf/profile/user <<'PROFILE'
user-db:user
system-db:local
PROFILE

if command -v dconf >/dev/null 2>&1; then
  dconf update || true
fi

cat > /usr/local/bin/udroid-gnome-x11 <<'LAUNCH'
#!/usr/bin/env bash
set -Eeuo pipefail

die() {
  printf '[udroid-gnome] ERROR: %s\n' "$*" >&2
  exit 1
}

# Do not inherit experimental VirGL, KGSL, Turnip, or custom Mesa loader
# settings. Those settings caused Mutter to lose its rendering connection.
unset MESA_LOADER_DRIVER_OVERRIDE
unset FD_FORCE_KGSL
unset TURNIP_KMD
unset VK_ICD_FILENAMES
unset VK_LOADER_LAYERS_DISABLE
unset LD_LIBRARY_PATH
unset LIBGL_DRIVERS_PATH
unset EGL_DRIVERS_PATH
unset __EGL_VENDOR_LIBRARY_FILENAMES
unset DBUS_SESSION_BUS_ADDRESS
unset DBUS_SYSTEM_BUS_ADDRESS

export DISPLAY="${DISPLAY:-:0}"
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=gnome
export DESKTOP_SESSION=gnome
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export GSK_RENDERER=cairo
export GDK_BACKEND=x11

# A private runtime directory is required by modern GNOME. Allow an explicit
# override, otherwise keep each Unix user in a separate directory.
export XDG_RUNTIME_DIR="${UDROID_GNOME_RUNTIME_DIR:-/tmp/gnome-runtime-$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR" || die "cannot create $XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR" || die "cannot secure $XDG_RUNTIME_DIR"

if ! command -v gnome-shell >/dev/null 2>&1; then
  die "gnome-shell is not installed"
fi

if command -v xdpyinfo >/dev/null 2>&1 &&
   ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  die "cannot connect to the X server at DISPLAY=$DISPLAY; start Termux:X11 first"
fi

# Ensure the machine ID exists before starting a system bus.
if command -v dbus-uuidgen >/dev/null 2>&1; then
  dbus-uuidgen --ensure=/etc/machine-id
fi

# Make sure the system bus is healthy without killing an already-working bus.
if ! dbus-send --system --print-reply \
  --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames \
  >/dev/null 2>&1; then
  mkdir -p /run/dbus
  rm -f /run/dbus/pid /run/dbus/system_bus_socket

  if command -v service >/dev/null 2>&1; then
    service dbus start || true
  fi

  if ! dbus-send --system --print-reply \
    --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames \
    >/dev/null 2>&1; then
    dbus-daemon --system --fork --nopidfile --nosyslog ||
      die "could not start the system D-Bus daemon"
  fi
fi

dbus-send --system --print-reply \
  --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames \
  >/dev/null 2>&1 || die "the system D-Bus is not responding"

exec dbus-run-session -- gnome-shell --x11 --sm-disable
LAUNCH
chmod 0755 /usr/local/bin/udroid-gnome-x11

cat > /root/start-gnome.sh <<'LAUNCH'
#!/usr/bin/env bash
exec /usr/local/bin/udroid-gnome-x11 "$@"
LAUNCH
chmod 0755 /root/start-gnome.sh
