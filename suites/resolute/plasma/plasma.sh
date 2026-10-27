#!/usr/bin/env bash
export DISTRIBUTION=ubuntu

exec bash ../shared/plasma/build.sh resolute "$@"
