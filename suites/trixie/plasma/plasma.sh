#!/usr/bin/env bash
export DISTRIBUTION=debian

exec bash ../shared/plasma/build.sh trixie "$@"
