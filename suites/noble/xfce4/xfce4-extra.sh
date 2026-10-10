#!/usr/bin/env bash
# Useful lightweight XFCE applications.
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get install -y --no-install-recommends \
    mousepad \
    ristretto \
    xarchiver
