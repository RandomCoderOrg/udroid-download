import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
VARIANT = ROOT / "suites" / "plucky" / "gnomeRaw"
SCRIPTS = [
    VARIANT / "gnomeRaw.sh",
    VARIANT / "gnomeRaw-setup.sh",
    VARIANT / "gnomeRaw-extras.sh",
    VARIANT / "gnomeRaw-fixes.sh",
    VARIANT / "gnomeRaw-cleanup.sh",
]


class PluckyGnomeBuildTest(unittest.TestCase):
    def test_matrix_contains_only_arm64_for_plucky_gnome(self):
        output = subprocess.check_output(
            [sys.executable, "gen_data/gen-suite-matrix.py"],
            cwd=ROOT,
            text=True,
        )
        matrix = json.loads(output)["include"]
        entries = [
            item for item in matrix
            if item["suite"] == "plucky" and item["variant"] == "gnomeRaw"
        ]
        self.assertEqual(
            entries,
            [{"suite": "plucky", "variant": "gnomeRaw", "architecture": "arm64"}],
        )

    def test_variant_scripts_and_embedded_launcher_have_valid_bash_syntax(self):
        for script in SCRIPTS:
            with self.subTest(script=script.name):
                result = subprocess.run(
                    ["bash", "-n", str(script)],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)

        fixes = (VARIANT / "gnomeRaw-fixes.sh").read_text(encoding="utf-8")
        match = re.search(
            r"cat > /usr/local/bin/udroid-gnome-x11 <<'LAUNCH'\n(.*?)\nLAUNCH",
            fixes,
            re.DOTALL,
        )
        self.assertIsNotNone(match, "launcher heredoc is missing")
        result = subprocess.run(
            ["bash", "-n"],
            input=match.group(1),
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_build_entrypoint_provisions_rootfs_and_cleans_mounts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cook = root / "fs-cook"
            (cook / "plugins").mkdir(parents=True)
            for path in VARIANT.iterdir():
                if path.is_file() and not path.name.startswith("."):
                    shutil.copy2(path, cook / path.name)

            record = root / "calls.log"
            envsetup = cook / "plugins" / "envsetup"
            envsetup.write_text(
                """#!/usr/bin/env bash
ROOT_DIR="$(pwd)"
die() { echo "$*" >&2; exit 1; }
shout() { :; }
lshout() { :; }
do_chroot_ae() {
  local rootfs="$1"
  local command="$2"
  local script="${command##*/}"
  test -s "$rootfs/tmp/$script"
  printf 'script:%s\\n' "$script" >> "$CALL_LOG"
}
do_build() {
  local target="$1"
  local architecture="$2"
  chroot_dir="$target"
  MIRROR="http://ports.ubuntu.com/ubuntu-ports/"
  mkdir -p "$chroot_dir/etc/apt" "$chroot_dir/tmp"
  additional_setup
  mkdir -p out
  : > "out/$(basename "$target").tar.gz"
  printf 'build:%s:%s\\n' "$target" "$architecture" >> "$CALL_LOG"
}
do_compress() {
  printf 'unexpected-explicit-compress\\n' >> "$CALL_LOG"
}
do_unmount() {
  printf 'unmount:%s\\n' "$1" >> "$CALL_LOG"
}
""",
                encoding="utf-8",
            )

            result = subprocess.run(
                ["bash", "gnomeRaw.sh", "arm64"],
                cwd=cook,
                env={**os.environ, "CALL_LOG": str(record)},
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            calls = record.read_text(encoding="utf-8").splitlines()
            for script in (
                "gnomeRaw-setup.sh",
                "gnomeRaw-extras.sh",
                "gnomeRaw-fixes.sh",
                "gnomeRaw-cleanup.sh",
            ):
                self.assertIn(f"script:{script}", calls)

            target = cook / "out" / "plucky-gnomeRaw-arm64"
            sources = (target / "etc" / "apt" / "sources.list").read_text(encoding="utf-8")
            self.assertIn("plucky main restricted universe multiverse", sources)
            self.assertIn("plucky-updates", sources)
            self.assertIn("plucky-backports", sources)
            self.assertTrue(
                (target / "etc" / "dconf" / "db" / "local.d" / "00-udroid-gnome").is_file()
            )

            self.assertTrue(any(line.startswith("build:out/plucky-gnomeRaw-arm64:arm64") for line in calls))
            self.assertEqual(
                [line for line in calls if line.startswith("unmount:")],
                ["unmount:out/plucky-gnomeRaw-arm64"],
            )
            self.assertNotIn("unexpected-explicit-compress", calls)
            self.assertTrue((cook / "out" / "plucky-gnomeRaw-arm64.tar.gz").is_file())
            self.assertFalse((target / "tmp" / "gnomeRaw-setup.sh").exists())

    def test_launcher_overrides_virgl_and_starts_fresh_session_bus(self):
        fixes = (VARIANT / "gnomeRaw-fixes.sh").read_text(encoding="utf-8")
        match = re.search(
            r"cat > /usr/local/bin/udroid-gnome-x11 <<'LAUNCH'\n(.*?)\nLAUNCH",
            fixes,
            re.DOTALL,
        )
        self.assertIsNotNone(match, "launcher heredoc is missing")

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bindir = root / "bin"
            bindir.mkdir()
            runtime = root / "runtime"
            launch_record = root / "launch.txt"
            service_record = root / "service.txt"
            dbus_count = root / "dbus-count"

            def stub(name, body):
                path = bindir / name
                path.write_text(body, encoding="utf-8")
                path.chmod(0o755)

            stub("xdpyinfo", "#!/bin/sh\nexit 0\n")
            # The launcher removes stale /run/dbus files before retrying.
            # Never let this unit test touch the host container's bus files.
            stub("rm", "#!/bin/sh\nexit 0\n")
            stub(
                "service",
                "#!/bin/sh\nprintf '%s\\n' \"$*\" > \"$SERVICE_RECORD\"\nexit 0\n",
            )
            stub(
                "dbus-send",
                """#!/bin/sh
count=0
[ -f "$DBUS_COUNT" ] && count="$(cat "$DBUS_COUNT")"
count=$((count + 1))
printf '%s' "$count" > "$DBUS_COUNT"
[ "$count" -ge 2 ]
""",
            )
            stub(
                "dbus-run-session",
                "#!/bin/sh\n[ \"$1\" = \"--\" ] || exit 90\nshift\nexec \"$@\"\n",
            )
            stub(
                "gnome-shell",
                """#!/bin/sh
{
  printf 'DISPLAY=%s\\n' "$DISPLAY"
  printf 'XDG_RUNTIME_DIR=%s\\n' "$XDG_RUNTIME_DIR"
  printf 'LIBGL_ALWAYS_SOFTWARE=%s\\n' "$LIBGL_ALWAYS_SOFTWARE"
  printf 'GALLIUM_DRIVER=%s\\n' "$GALLIUM_DRIVER"
  printf 'GSK_RENDERER=%s\\n' "$GSK_RENDERER"
  printf 'MESA_LOADER_DRIVER_OVERRIDE=%s\\n' "${MESA_LOADER_DRIVER_OVERRIDE-unset}"
  printf 'FD_FORCE_KGSL=%s\\n' "${FD_FORCE_KGSL-unset}"
  printf 'LD_LIBRARY_PATH=%s\\n' "${LD_LIBRARY_PATH-unset}"
  printf 'ARGS=%s\\n' "$*"
} > "$LAUNCH_RECORD"
""",
            )

            launch_path = root / "udroid-gnome-x11"
            launch_path.write_text(match.group(1) + "\n", encoding="utf-8")
            launch_path.chmod(0o755)

            result = subprocess.run(
                [str(launch_path)],
                env={
                    **os.environ,
                    "PATH": f"{bindir}:{os.environ['PATH']}",
                    "DISPLAY": ":0",
                    "GALLIUM_DRIVER": "virpipe",
                    "MESA_LOADER_DRIVER_OVERRIDE": "kgsl",
                    "FD_FORCE_KGSL": "1",
                    "LD_LIBRARY_PATH": "/tmp/mesa-test",
                    "UDROID_GNOME_RUNTIME_DIR": str(runtime),
                    "LAUNCH_RECORD": str(launch_record),
                    "SERVICE_RECORD": str(service_record),
                    "DBUS_COUNT": str(dbus_count),
                },
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            output = launch_record.read_text(encoding="utf-8")
            self.assertIn("DISPLAY=:0", output)
            self.assertIn(f"XDG_RUNTIME_DIR={runtime}", output)
            self.assertIn("LIBGL_ALWAYS_SOFTWARE=1", output)
            self.assertIn("GALLIUM_DRIVER=llvmpipe", output)
            self.assertIn("GSK_RENDERER=cairo", output)
            self.assertIn("MESA_LOADER_DRIVER_OVERRIDE=unset", output)
            self.assertIn("FD_FORCE_KGSL=unset", output)
            self.assertIn("LD_LIBRARY_PATH=unset", output)
            self.assertIn("ARGS=--x11 --sm-disable", output)
            self.assertEqual(service_record.read_text(encoding="utf-8").strip(), "dbus start")
            self.assertEqual(runtime.stat().st_mode & 0o777, 0o700)


if __name__ == "__main__":
    unittest.main()
