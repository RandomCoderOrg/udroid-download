#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
# shellcheck disable=SC1091
source /etc/os-release
case "$ID" in
    debian) distro_packages=(fonts-liberation adwaita-icon-theme) ;;
    ubuntu) distro_packages=(fonts-ubuntu adwaita-icon-theme-full plasma-session-x11) ;;
    *) echo "Unsupported Plasma distribution: $ID" >&2; exit 1 ;;
esac

cp -a /udroid-build/overlay/. /
chmod 0755 \
    /usr/sbin/policy-rc.d \
    /usr/local/bin/udroid-desktop \
    /usr/local/bin/udroid-session-run \
    /usr/local/bin/udroid-plasma-session \
    /usr/local/bin/udroid-mactahoe \
    /usr/local/bin/udroid-app-probe \
    /usr/local/bin/udroid-app-report \
    /usr/local/libexec/udroid-install-mactahoe-assets \
    /usr/local/libexec/udroid/firefox \
    /usr/local/libexec/udroid/chromium \
    /usr/local/libexec/udroid/code \
    /usr/local/libexec/udroid/install-firefox \
    /usr/local/libexec/udroid/install-chromium \
    /usr/local/libexec/udroid/install-code
chmod 0440 /etc/sudoers.d/90-udroid

apt-get update
apt-get -y dist-upgrade
apt-get install -y --no-install-recommends \
    ca-certificates curl wget git less nano vim-tiny sudo locales \
    procps iproute2 net-tools file xz-utils zstd \
    dbus dbus-x11 x11-xserver-utils tigervnc-standalone-server tigervnc-tools \
    gvfs libgl1-mesa-dri mesa-utils \
    "${distro_packages[@]}" fonts-noto-core fonts-noto-color-emoji \
    fonts-inter-variable fonts-jetbrains-mono \
    yaru-theme-gtk yaru-theme-icon \
    plasma-desktop plasma-workspace kwin-x11 \
    dolphin konsole systemsettings qt6-style-kvantum plasma-widgets-addons \
    ark kate okular gwenview keepassxc mpv kcalc \
    kde-spectacle plasma-systemmonitor \
    libnotify-bin python3-minimal util-linux x11-utils

sed -i 's/^# *en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
if ! id udroid >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash --groups sudo,audio,video,plugdev udroid
fi
printf '%s\n' 'udroid:udroid' | chpasswd

install -d -o udroid -g udroid /home/udroid/.config /home/udroid/Desktop
cp -a /etc/skel/. /home/udroid/
chown -R udroid:udroid /home/udroid

install -d -m 0700 -o udroid -g udroid /home/udroid/.config/tigervnc
if [ ! -s /home/udroid/.config/tigervnc/passwd ]; then
    printf %s udroid | tigervncpasswd -f > /home/udroid/.config/tigervnc/passwd
fi
chown udroid:udroid /home/udroid/.config/tigervnc/passwd
chmod 0600 /home/udroid/.config/tigervnc/passwd

/usr/local/libexec/udroid-install-mactahoe-assets
/usr/local/libexec/udroid/install-firefox
/usr/local/libexec/udroid/install-chromium
/usr/local/libexec/udroid/install-code
update-desktop-database /usr/local/share/applications 2>/dev/null || true

# Apply the profile during the first real X11 session, where Plasma's tools
# have a display and session bus. This keeps the packed home directory free of
# transient VNC and D-Bus state.
touch /home/udroid/.config/.udroid-mactahoe-pending
chown udroid:udroid /home/udroid/.config/.udroid-mactahoe-pending

printf 'uDroid %s Plasma\n' "$PRETTY_NAME" > /etc/udroid-image
touch /.udroid-plasma-ready

apt-get clean
rm -rf \
    /var/lib/apt/lists/* \
    /var/cache/apt/archives/* \
    /var/cache/udroid-apps \
    /var/log/*.log \
    /var/log/apt/* \
    /root/.cache \
    /home/udroid/.cache \
    /tmp/* /var/tmp/* \
    /udroid-build \
    /plasma-setup.sh
rm -f /etc/machine-id /var/lib/dbus/machine-id
touch /etc/machine-id
