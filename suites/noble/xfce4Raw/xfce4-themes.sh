#!/usr/bin/env bash
# Install upstream GTK and icon themes during the Noble rootfs build.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates curl unzip sassc \
    gtk2-engines-murrine gtk2-engines-pixbuf

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fL --retry 3 \
  https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/heads/master.zip \
  -o "$tmp/whitesur.zip"
curl -fL --retry 3 \
  https://github.com/vinceliuice/Tela-icon-theme/archive/refs/heads/master.zip \
  -o "$tmp/tela.zip"

mkdir "$tmp/whitesur" "$tmp/tela"
unzip -q "$tmp/whitesur.zip" -d "$tmp/whitesur"
unzip -q "$tmp/tela.zip" -d "$tmp/tela"

gtk_src="$(find "$tmp/whitesur" -mindepth 1 -maxdepth 1 -type d | head -1)"
icon_src="$(find "$tmp/tela" -mindepth 1 -maxdepth 1 -type d | head -1)"

test -x "$gtk_src/install.sh"
test -x "$icon_src/install.sh"

(
  cd "$gtk_src"
  bash ./install.sh --dest /usr/share/themes \
    --name udroid-xfsmooth --color light --silent-mode
)
(
  cd "$icon_src"
  bash ./install.sh -d /usr/share/icons -n udroid-tela black
)

test -f /usr/share/themes/udroid-xfsmooth-light/index.theme
test -f /usr/share/icons/udroid-tela-black/index.theme
