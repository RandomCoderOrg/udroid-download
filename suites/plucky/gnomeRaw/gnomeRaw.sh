#!/usr/bin/env bash
set -Ee

# fs-cook variant entry point for the Plucky GNOME X11 image.
source plugins/envsetup

SUITE=plucky
VARIENT=gnomeRaw
frn=out/plucky-gnomeRaw
OVERRIDER_COMPRESSION_TYPE=gzip
ENABLE_EXIT=true
ENABLE_USER_SETUP=false

additional_setup() {
  # Plucky is built for ARM64 using the same Ports mirror used by the
  # Plucky rootfs. Keep this list aligned with the release's supported pockets.
  cat > "$chroot_dir/etc/apt/sources.list" <<SOURCES
# Ubuntu Plucky repositories
deb $MIRROR $SUITE main restricted universe multiverse
deb $MIRROR $SUITE-updates main restricted universe multiverse
deb $MIRROR $SUITE-backports main restricted universe multiverse
SOURCES

  mkdir -p "$chroot_dir/etc/dconf/db/local.d" "$chroot_dir/tmp"
  cp "$ROOT_DIR/plucky.dconf.conf" \
    "$chroot_dir/etc/dconf/db/local.d/00-udroid-gnome"

  for script in \
    gnomeRaw-setup.sh \
    gnomeRaw-extras.sh \
    gnomeRaw-fixes.sh \
    gnomeRaw-cleanup.sh; do
    lshout "Running $script inside rootfs"
    cp "$ROOT_DIR/$script" "$chroot_dir/tmp/$script"
    do_chroot_ae "$chroot_dir" "/bin/bash /tmp/$script"
    rm -f "$chroot_dir/tmp/$script"
  done
}

build_target=""
cleanup_build() {
  if [[ -n "$build_target" && -d "$build_target" ]]; then
    do_unmount "$build_target" || true
  fi
}
trap cleanup_build EXIT

case "${1:-all}" in
  arm64|all)
    # This target deliberately supports ARM64 only. Its CI manifest keeps
    # the default build matrix from trying unsupported architectures.
    arch=arm64
    ;;
  *)
    die "Plucky GNOME supports arm64 only (usage: $0 [arm64|all])"
    ;;
esac

build_target="${frn}-${arch}"
shout "Building Plucky GNOME for ${arch}"

# fs-cook's do_build() performs compression unless NO_COMPRESSION is set.
# Do not call do_compress() again here; that would pack the same rootfs twice.
do_build "$build_target" "$arch"
do_unmount "$build_target"
build_target=""

shout "Plucky GNOME build complete"
ls -lh "${frn}-${arch}.tar.gz"
