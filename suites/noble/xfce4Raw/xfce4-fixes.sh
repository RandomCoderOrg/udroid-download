#!/usr/bin/env bash
# Configure XFCE startup for Termux:X11/PRoot.
set -e

# Ensure the custom theme remains selected in the XFCE settings files.
for home in /root /etc/skel; do
    settings="$home/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
    window_settings="$home/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"

    if [ -f "$settings" ]; then
        sed -i 's/name="ThemeName" type="string" value="[^"]*"/name="ThemeName" type="string" value="udroid-xfsmooth-light"/' "$settings"
        sed -i 's/name="IconThemeName" type="string" value="[^"]*"/name="IconThemeName" type="string" value="udroid-tela-black"/' "$settings"
    fi
    if [ -f "$window_settings" ]; then
        sed -i 's/name="theme" type="string" value="[^"]*"/name="theme" type="string" value="udroid-xfsmooth-light"/' "$window_settings"
    fi

    mkdir -p "$home/.config" "$home/Desktop" "$home/Downloads" \
        "$home/Documents" "$home/Music" "$home/Pictures" "$home/Videos"
    cat > "$home/.config/user-dirs.dirs" <<'EOF_USER_DIRS'
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
EOF_USER_DIRS
done

cat > /etc/profile.d/xfce-termux-x11.sh <<'EOF_PROFILE'
export DISPLAY="${DISPLAY:-:0}"
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
EOF_PROFILE
chmod 0644 /etc/profile.d/xfce-termux-x11.sh

cat > /usr/local/bin/udroid-xfce4-x11 <<'EOF_LAUNCHER'
#!/usr/bin/env bash
set -e

export DISPLAY="${DISPLAY:-:0}"
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export GDK_BACKEND=x11
export GSK_RENDERER=cairo
export LIBGL_ALWAYS_SOFTWARE=1
export XDG_RUNTIME_DIR=/tmp/xdg-runtime-root
unset GALLIUM_DRIVER MESA_LOADER_DRIVER_OVERRIDE

mkdir -p "$XDG_RUNTIME_DIR" /run/dbus
chmod 0700 "$XDG_RUNTIME_DIR"
chmod 0755 /run/dbus

# PRoot does not run systemd. Start a system D-Bus daemon if one is absent.
if ! dbus-send --system --dest=org.freedesktop.DBus \
    --type=method_call --print-reply / org.freedesktop.DBus.ListNames \
    >/dev/null 2>&1; then
    rm -f /run/dbus/system_bus_socket /run/dbus/pid
    /usr/bin/dbus-daemon --system \
        --address=unix:path=/run/dbus/system_bus_socket \
        --fork --nopidfile
fi

exec dbus-launch --exit-with-session startxfce4
EOF_LAUNCHER
chmod 0755 /usr/local/bin/udroid-xfce4-x11
