#!/bin/bash

die()    { echo -e "[E] ${*}";exit 1;:;}
warn()   { echo -e "[W] ${*}";:;}
shout()  { echo -e "[-] ${*}";:;}
lshout() { echo -e "-> ${*}";:;}
msg()    { echo -e "${*} \e[0m" >&2;:;}

DEPS="git build-essential binfmt-support qemu-user-static debootstrap"

# ROOT user check
if ((UID != 0 )); then
    die "please run this script as root"
else
    SUDO=$(which sudo)
fi

# Force install dependencies
shout "Resolving Dependencies"
$SUDO apt update || {
    die "Failed to update indexes"
}
$SUDO apt install -y "$DEPS" || {
    die "Failed to install packages.."
}

# pull submodules
shout "Trying to update submodules.."
git submodule init
git submoudule update || {
    die "Failed to pull submodules."
}

shout "DONE."
