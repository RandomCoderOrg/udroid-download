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
