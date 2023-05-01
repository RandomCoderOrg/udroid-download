#!/bin/bash

apt-get update
apt-get install --no-install-recommends kubuntu-desktop kubuntu-wallpapers dbus-x11 xterm tigervnc-xorg-extension -y
apt-get clean
