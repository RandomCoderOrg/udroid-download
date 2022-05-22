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

function build() {
    # load suites
    _avalible_suites="$(find ./suites -type d | cut -d / -f 3 | awk 'NF' | uniq -u | tr '\n' ' ')"

    # check is SUITE avalible in ./suites
    if [[ ! ${_avalible_suites} =~ $SUITE ]]; then
        die "$SUITE not found in ./suites"
    fi

    # load avalible varients
    _avalible_varients=$(find ./suites/"$SUITE" -type f | cut -d / -f 4 | awk 'NF')

    # check is varient script avalible
    if [[ ! ${_avalible_varients} =~ $VARIENT ]]; then
        die "$VARIENT install script not found"
    fi

    # Execute script
    cd fs-cook || die "failed to cd ./fs-cook" # script need to executed from fs-cook root directory
    bash ../suites/"$SUITE"/"$VARIENT" "$ARCH"
}

function _list() {
    for _suite in $(find ./suites -type d | cut -d / -f 3 | awk 'NF' | uniq -u | tr '\n' ' '); do
        echo "[SUITE] _suite"
        for _varient in $(find ./suites/"$_suite" -type f | cut -d / -f 4 | awk 'NF'); do
            echo -e "\t $_varient"
        done
    done
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
