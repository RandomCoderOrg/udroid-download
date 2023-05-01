#!/bin/bash

apt-get update
apt-get install --no-install-recommends xubuntu-core xubuntu-icon-theme xubuntu-wallpapers xubuntu-wallpapers dbus-x11 xterm tigervnc-xorg-extension -y
apt-get clean
