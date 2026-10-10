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

    # Install XFCE and configure themes at build time without bundling assets.
    run_shell_script "$VARIENT-setup.sh"
    run_shell_script "$VARIENT-extra.sh"
    run_shell_script "$VARIENT-themes.sh"
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
