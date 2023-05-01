#!/bin/bash

apt-get update
apt-get install --no-install-recommends gnome-shell dbus-x11 xterm tigervnc-xorg-extension -y
apt-get clean
