#!/usr/bin/env bash
# shellcheck disable=SC1091

source plugins/envsetup

export SUITE="resolute"
export OVERRIDER_COMPRESSION_TYPE="gzip"
export ENABLE_EXIT=true
export ENABLE_USER_SETUP=false
export INCLUDE_PACKAGES="ca-certificates gpgv"

frn="out/${SUITE}-plasma"

additional_setup() {
    cat > "$chroot_dir/etc/apt/sources.list" <<EOF
deb $MIRROR $SUITE main restricted universe multiverse
deb $MIRROR $SUITE-updates main restricted universe multiverse
deb $MIRROR $SUITE-backports main restricted universe multiverse
deb $MIRROR $SUITE-security main restricted universe multiverse
EOF

    $SUDO install -d "$chroot_dir/udroid-build/overlay"
    $SUDO cp -a plasma-overlay/. "$chroot_dir/udroid-build/overlay/"
    $SUDO chown -R 0:0 "$chroot_dir/udroid-build"

    run_shell_script plasma-setup.sh

    if ! $SUDO test -f "$chroot_dir/.udroid-plasma-ready"; then
        die "Plasma provisioning did not produce its success marker"
    fi
}

case "${1:-}" in
    arm64) architectures="arm64" ;;
    all | -a) architectures="arm64" ;;
    *) die "The Plasma image currently supports ARM64 only" ;;
esac

for arch in $architectures; do
    shout "Bootstrapping $SUITE Plasma [$arch]"
    do_build "${frn}-${arch}" "$arch"
    shout "Unmounting the root filesystem"
    do_unmount "${frn}-${arch}"
done

shout "Build complete"
ls "${frn}"*.tar.*
