#!/bin/bash

apt-get update
apt-get install --no-install-recommends lubuntu-desktop lubuntu-default-settings lubuntu-artwork lubuntu-restricted-addons dbus-x11 xterm tigervnc-xorg-extension -y
apt-get clean
