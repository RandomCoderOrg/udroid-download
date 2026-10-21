#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get install -y \
  gnome-system-monitor gnome-text-editor gnome-calculator gnome-calendar \
  gnome-clocks file-roller evince yaru-theme-icon
