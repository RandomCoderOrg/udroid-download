[![CodeFactor](https://www.codefactor.io/repository/github/thatmg393/udroid-download/badge/main)](https://www.codefactor.io/repository/github/thatmg393/udroid-download/overview/main)

# udroid-download

An ( fs-cook &amp; debootstrap ) wrapper to build udroid with cmdline

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

The release generator reads `ID` from each completed archive's `os-release`
file and records it in `distro-data.json`. New variants need no separate distro
mapping; conflicting IDs within one suite fail release metadata generation.
