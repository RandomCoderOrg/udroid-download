[![CodeFactor](https://www.codefactor.io/repository/github/thatmg393/udroid-download/badge/main)](https://www.codefactor.io/repository/github/thatmg393/udroid-download/overview/main)

# udroid-download
An ( fs-cook & debootstrap ) wrapper to build udroid with cmdline.
## Ubuntu Plucky GNOME X11 image
The `plucky/gnomeRaw` target builds an ARM64 Ubuntu Plucky GNOME desktop
image for Termux:X11. GNOME is launched with Mesa's `llvmpipe` software
renderer and GTK's Cairo renderer by default. The launcher clears conflicting
VirGL/KGSL/Turnip loader overrides before starting GNOME.

Build it with:

```sh
sudo bash build.sh -s plucky -v gnomeRaw -a arm64
```

The image is written to
`fs-cook/out/plucky-gnomeRaw-arm64.tar.gz`. After extracting the rootfs and
starting Termux:X11, launch GNOME from the rootfs with:

```sh
udroid-gnome-x11
```

The `udroid-gnome-x11` launcher starts the system D-Bus when needed, creates a
per-user runtime directory, checks the X11 connection, and starts a fresh
session D-Bus for GNOME. It intentionally uses CPU rendering; it does not
attempt to enable VirGL or direct KGSL acceleration.

## Resolute Plasma image

The `resolute/plasma` target builds the ARM64 Ubuntu 26.04 desktop image. It
contains Plasma X11 with the pinned MacTahoe profile, uDroid session helpers,
Firefox, Chromium, Visual Studio Code, and the daily desktop applications. The
image intentionally does not carry the older Xfce desktop.

```sh
sudo bash build.sh -s resolute -v plasma -a arm64
```

The finished archive is written to
`fs-cook/out/resolute-plasma-arm64.tar.gz`. The target is included in the CI
matrix and declares its supported architecture in `.architectures`.

## Debian Trixie Plasma image

The `trixie/plasma` target builds a Debian 13 ARM64 image with the same Plasma
X11 desktop, MacTahoe profile, session helpers, and development applications.
Chromium and Firefox ESR come directly from Debian's APT repositories, including
security updates. VS Code uses the existing verified Microsoft `.deb` installer.
Snap and Flatpak are not required.

```sh
sudo bash build.sh -s trixie -v plasma -a arm64
```

The archive is `fs-cook/out/trixie-plasma-arm64.tar.gz`. CI discovers the target
automatically; the release job adds its URL and checksum to `distro-data.json`
after a successful build and release. Both Plasma targets share the provisioning
scripts and overlay in `shared/plasma/`.
