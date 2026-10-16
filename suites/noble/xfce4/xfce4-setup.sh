#!/usr/bin/env bash
# Required XFCE desktop packages for Noble on Termux:X11/PRoot.
set -e

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C
export LANGUAGE=C
export LANG=C

apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    dbus \
    dbus-bin \
    dbus-x11 \
    fonts-ubuntu \
    gvfs \
    gvfs-backends \
    thunar \
    thunar-volman \
    tumbler \
    x11-xserver-utils \
    xauth \
    xterm \
    xfce4 \
    xfce4-clipman-plugin \
    xfce4-genmon-plugin \
    xfce4-indicator-plugin \
    xfce4-notifyd \
    xfce4-panel \
    xfce4-pulseaudio-plugin \
    xfce4-screenshooter \
    xfce4-sntray-plugin \
    xfce4-taskmanager \
    xfce4-terminal \
    xfce4-whiskermenu-plugin \
    xfce4-xkb-plugin
