#!/usr/bin/env bash
# Build the Ubuntu Noble XFCE4 variant for uDroid.
# shellcheck disable=SC1091

source plugins/envsetup

export OVERRIDER_COMPRESSION_TYPE SUITE ENABLE_EXIT ENABLE_USER_SETUP INCLUDE_PACKAGES
SUITE="noble"
VARIENT="xfce4"
frn="out/$SUITE-$VARIENT"
OVERRIDER_COMPRESSION_TYPE="gzip"
ENABLE_EXIT=true
ENABLE_USER_SETUP=false
INCLUDE_PACKAGES="gpgv"

additional_setup() {
    cat > "$chroot_dir/etc/apt/sources.list" <<EOF_SOURCES
# Ubuntu Noble repositories for uDroid.
deb $MIRROR $SUITE main restricted universe multiverse
deb $MIRROR $SUITE-updates main restricted universe multiverse
deb $MIRROR $SUITE-backports main restricted universe multiverse
EOF_SOURCES

    lshout "Setting up pv..."
    cp "$ROOT_DIR/core/pv/pv-${t_arch}.deb" "$chroot_dir/"
    run_cmd "dpkg -i /pv-${t_arch}.deb"
    run_cmd "rm -f /pv-${t_arch}.deb"

    # ROOT_DIR is the fs-cook repository; suite sources live beside it.
    local assets_dir="$ROOT_DIR/../suites/$SUITE/$VARIENT/assets"
    [ -d "$assets_dir/themes/udroid-xfsmooth-light" ] || die "Missing bundled GTK theme: $assets_dir"
    [ -d "$assets_dir/icons/udroid-tela-black" ] || die "Missing bundled icon theme: $assets_dir"
    [ -d "$assets_dir/config/xfce-perchannel-xml" ] || die "Missing bundled XFCE configuration: $assets_dir"

    mkdir -p "$chroot_dir/usr/share/themes" "$chroot_dir/usr/share/icons"
    cp -r "$assets_dir/themes/udroid-xfsmooth-light" "$chroot_dir/usr/share/themes/"
    cp -r "$assets_dir/icons/udroid-tela-black" "$chroot_dir/usr/share/icons/"
    chmod -R a+rX "$chroot_dir/usr/share/themes/udroid-xfsmooth-light" \
        "$chroot_dir/usr/share/icons/udroid-tela-black"

    # Install settings for root and as defaults for subsequently created users.
    local home cfg
    for home in "$chroot_dir/root" "$chroot_dir/etc/skel"; do
        cfg="$home/.config/xfce4"
        mkdir -p "$cfg/xfconf/xfce-perchannel-xml"
        cp -r "$assets_dir/config/xfce-perchannel-xml/." \
            "$cfg/xfconf/xfce-perchannel-xml/"
        if [ -d "$assets_dir/config/panel" ]; then
            cp -r "$assets_dir/config/panel" "$cfg/"
        fi
        find "$cfg" -type f -exec chmod 0644 {} +
    done

    # Intentionally do not copy Jammy's desktop wallpaper configuration.
    run_shell_script "$VARIENT-setup.sh"
    run_shell_script "$VARIENT-extra.sh"
    run_shell_script "$VARIENT-fixes.sh"
    run_shell_script "$VARIENT-cleanup.sh"
}

case "${1:-}" in
    arm64|armhf|amd64) _arch="$1" ;;
    all|-a) _arch="armhf arm64 amd64" ;;
    *) die "Usage: $0 {arm64|armhf|amd64|all}" ;;
esac

for arch in $_arch; do
    shout "Bootstrapping Noble XFCE4 [$arch]..."
    do_build "${frn}-${arch}" "$arch"
    shout "Packing Noble XFCE4 filesystem..."
    do_compress "${frn}-${arch}"
    shout "Unmounting Noble XFCE4 filesystem..."
    do_unmount "${frn}-${arch}"
done

shout "Noble XFCE4 build complete. Output files:"
ls -lh "${frn}"*tar*
