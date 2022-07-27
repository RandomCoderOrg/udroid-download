#!/usr/bin/env bash
#shellcheck disable=SC1091

# this is an example file to BUILD raw file system
# export variable SUITE to set debootstrap suite name (default: hirsute)

source plugins/envsetup

export OVERRIDER_COMPRESSION_TYPE
export SUITE
export ENABLE_EXIT
export ENABLE_USER_SETUP
export COMPONENTS

SUITE="kinetic"
frn="out/$SUITE-raw"
OVERRIDER_COMPRESSION_TYPE="gzip"
ENABLE_EXIT=true
ENABLE_USER_SETUP=false
COMPONENTS="multiverse,universe,main,restricted"


additional_setup() {

# update sources.list [Only for ubuntu suites]
cat <<-EOF >$chroot_dir/etc/apt/sources.list
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb $MIRROR $SUITE main restricted
# deb-src $MIRROR $SUITE main restricted
## Major bug fix updates produced after the final release of the
## distribution.
deb $MIRROR $SUITE-updates main restricted
# deb-src $MIRROR $SUITE-updates main restricted
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb $MIRROR $SUITE universe
# deb-src $MIRROR $SUITE universe
deb $MIRROR $SUITE-updates universe
# deb-src $MIRROR $SUITE-updates universe
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb $MIRROR $SUITE multiverse
# deb-src $MIRROR $SUITE multiverse
deb $MIRROR $SUITE-updates multiverse
# deb-src $MIRROR $SUITE-updates multiverse
## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb $MIRROR $SUITE-backports main restricted universe multiverse
# deb-src $MIRROR $SUITE-backports main restricted universe multiverse
EOF

}

# Option to build specific arch
# arch name as $1

case $1 in
arm64 | armhf | amd64 | i386 ) _arch="$1" ;;
all | -a) _arch="armhf arm64 amd64 i386" ;;
*) die "Unknown arch option [ Allowed: arm64, armhf, amd64, i386, all(for all 4) ]" ;;
esac

for arch in ${_arch}; do
    shout "Bootstrapping $SUITE [${arch}] ...."
    do_build "${frn}-${arch}" "${arch}"
    shout "packing up the raw file systems..."
    do_compress "${frn}-${arch}"
    shout "unmounting the raw file systems from host..."
    do_unmount "${frn}-${arch}"
done

shout "Build Complete.."
ls ${frn}*tar*
