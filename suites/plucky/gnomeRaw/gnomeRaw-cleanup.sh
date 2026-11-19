#!/usr/bin/env bash
set -Eeuo pipefail
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
