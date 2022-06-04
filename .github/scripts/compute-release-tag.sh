#!/bin/bash

BUILD_TYPE="AB"

# udroid-on-android latest tag
udroid_version=$(
     git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' \
     https://github.com/RandomCoderOrg/ubuntu-on-android \
     | tail -n1 | cut -d / -f 3 | cut -d v -f 2-
)

# udroid-download version
udroid_download=$(
    git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' \
     https://github.com/RandomCoderOrg/udroid-download \
     | tail -n1 | cut -d / -f 3
)

version="V${udroid_version}${BUILD_TYPE}R$((${udroid_download: -1} + 1))"

# export version to github environment
echo "VERSIONTAG=$version" >> "$GITHUB_ENV"
