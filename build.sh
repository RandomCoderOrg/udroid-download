#!/bin/bash

# ///////////////////////////
# TODO

# BUILDER BP
# To Build
# * ${0} [-s|--suite] <suite_name> [-v|--varient] <varient_name> [-a|--arch] <arch_name>
#

# To List
# TODO
# * ${0} [-s|--suite] <suite_name> [-l|--list] [[FOR LATER]]
# * ${0} [-s|--suite] <suite_name> [-v|--varient] <varient_name> [-l|--list]
# TODO

# To show Help
# * ${0} [-h|--help]
#
# To show version
# * ${0} [--version]
#
# ///////////////////////////

VERSION="0.1 (DEV)"

die()    { echo -e "[E] ${*}";exit 1;:;}
warn()   { echo -e "[W] ${*}";:;}
shout()  { echo -e "[-] ${*}";:;}
lshout() { echo -e "-> ${*}";:;}
msg()    { echo -e "${*} \e[0m" >&2;:;}

# DEFAULTS
ARCH="all"
VARIENT="raw"
UD_ROOT_DIR=$(git rev-parse --show-toplevel)

function build() {
    # load suites
    _avalible_suites="$(find ./suites -maxdepth 1 -type d ! -name '*-*' | cut -d / -f 3 | awk 'NF' | uniq -u | tr '\n' ' ')"

    # check is SUITE avalible in ./suites
    if [[ ! ${_avalible_suites} =~ $SUITE ]]; then
        die "$SUITE not found in ./suites"
    fi

    # load avalible varients
    _avalible_varients=$(find ./suites/"$SUITE" -type d | cut -d / -f 4 | awk 'NF' | uniq -u | tr '\n' ' ')

    # check is varient script avalible
    if [[ ! ${_avalible_varients} =~ $VARIENT ]]; then
        die "$VARIENT install script not found"
    fi

    # Execute script
    shout "Triggering build:"
    msg "SUITE=$SUITE"
    msg "Varient=$VARIENT"
    msg "ARCH=$ARCH"

    cp -r ./suites/$SUITE/$VARIENT/$VARIENT* fs-cook
    cd fs-cook || die "Failed to cd.."
    bash $VARIENT.sh $ARCH || die "build script failed"
    cd $UD_ROOT_DIR || die "Failed fto cd "
    rm -rf fs-cook/$VARIENT*
}

function _list() {
    for _suite in $(find ./suites -maxdepth 1 -type d ! -name '*-*' | cut -d / -f 3 | awk 'NF' | uniq -u | tr '\n' ' '); do
        echo "[SUITE] $_suite"
        for _varient in $(find ./suites/"$_suite" -type d ! -name '*-*' | cut -d / -f 4 | awk 'NF' | uniq -u | tr '\n' ' '); do
            echo -e "\t -$_varient"
        done
    done
}

function _help() {
    msg "udroid-download build tool V$VERSION"
    msg "USAGE: ${0} [options] [value]"
    msg "options:"
    msg "-s | --suite <suite_name> : To set suite name"
    msg "-v | --varient <varient_name>: To set varient name [ default = raw ]"
    msg "-a | --arch <arch name>: To set arch [ default = all ]"
    msg "-l | --list: To show all suites and varients"
    msg "examples:"
    msg "[To build impish suite raw varient] => bash ${0} -s impish -v raw"
    msg "[To build a specific arch type] => bash ${0} -s impish -v raw -a arm64"
    msg
    msg "This tool is specially built to automate tarball building with GitHub action or any workflows."
    msg "(C) RandomCoderOrg"
}

function _version() {
    msg "udroid-download build tool V$VERSION"
}

while (($# > 0)); do
    case $1 in
    -s | --suite)   SUITE=$2    ;shift 2 ;;
    -v | --varient) VARIENT=$2  ;shift 2 ;;
    -a | --arch)    ARCH=$2     ;shift 2 ;;
    --version)      _version    ;exit 0  ;;
    -h | --help)    _help       ;exit 0  ;;
    -l | --list)    _list       ;exit 0  ;;
    esac
done

# finally
build
