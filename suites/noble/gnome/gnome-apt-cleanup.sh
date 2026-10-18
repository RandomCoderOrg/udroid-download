#!/usr/bin/env bash
set -e
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
