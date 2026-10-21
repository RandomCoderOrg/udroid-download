#!/usr/bin/env bash
set -e

# fs-cook variant entry point for Ubuntu Noble GNOME.
source plugins/envsetup

SUITE=noble
VARIENT=gnome
frn=out/noble-gnomeRaw
OVERRIDER_COMPRESSION_TYPE=gzip
ENABLE_EXIT=true
ENABLE_USER_SETUP=false

additional_setup() {
  cat > "$chroot_dir/etc/apt/sources.list" <<SOURCES
# Ubuntu Noble repositories
deb $MIRROR $SUITE main restricted universe multiverse
deb $MIRROR $SUITE-updates main restricted universe multiverse
deb $MIRROR $SUITE-backports main restricted universe multiverse
SOURCES

  mkdir -p "$chroot_dir/etc/dconf/db/local.d"
  cp "$ROOT_DIR/noble.dconf.conf" \
     "$chroot_dir/etc/dconf/db/local.d/00-udroid-gnome"

  mkdir -p "$chroot_dir/tmp"
  for script in gnome-setup.sh gnome-extra.sh gnome-fixes.sh gnome-cleanup.sh; do
    lshout "Running $script inside rootfs"
    cp "$ROOT_DIR/$script" "$chroot_dir/tmp/$script"
    do_chroot_ae "$chroot_dir" "/bin/bash /tmp/$script"
    rm -f "$chroot_dir/tmp/$script"
  done
}

case "${1:-all}" in
  arm64|armhf|amd64|all) ;;
  *) die "Usage: $0 [arm64|armhf|amd64|all]" ;;
esac

# Keep this aligned with the existing fs-cook build pattern.
if [[ "${1:-all}" == "all" ]]; then
  shout "Building Noble GNOME for all supported architectures"
  do_build "${frn}-arm64" arm64
  do_build "${frn}-armhf" armhf
  do_build "${frn}-amd64" amd64
  do_compress "${frn}-arm64"
  do_compress "${frn}-armhf"
  do_compress "${frn}-amd64"
  do_unmount "${frn}-arm64"
  do_unmount "${frn}-armhf"
  do_unmount "${frn}-amd64"
else
  arch="$1"
  do_build "${frn}-${arch}" "$arch"
  do_compress "${frn}-${arch}"
  do_unmount "${frn}-${arch}"
fi

shout "Noble GNOME build complete"
ls -lh ${frn}*.tar.gz 2>/dev/null || true
