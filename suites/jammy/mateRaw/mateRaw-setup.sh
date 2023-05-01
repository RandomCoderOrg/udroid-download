#!/bin/bash

apt-get update
apt-get install --no-install-recommends ubuntu-mate-desktop ubuntu-mate-icon-themes ubuntu-mate-themes ubuntu-mate-wallpapers-common dbus-x11 xterm tigervnc-xorg-extension -y
apt-get clean
