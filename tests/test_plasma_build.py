import json
import io
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]


class PlasmaBuildTest(unittest.TestCase):
    def run_build(self, suite, architecture="arm64", provision_fail=""):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "shared").symlink_to(ROOT / "shared", target_is_directory=True)
            cook = root / "fs-cook"
            (cook / "plugins").mkdir(parents=True)
            record = root / "sources.list"
            (cook / "plugins/envsetup").write_text("""
die() { echo "$*" >&2; exit 1; }
shout() { :; }
do_build() {
    chroot_dir=$1
    MIRROR=${OVERRIDER_MIRROR:-https://ports.ubuntu.com/ubuntu-ports}
    mkdir -p "$chroot_dir/etc/apt"
    additional_setup
    cp "$chroot_dir/etc/apt/sources.list" "$RECORD"
}
run_shell_script() {
    test -s "$1" || exit 1
    test -f "$chroot_dir/udroid-build/overlay/usr/local/bin/udroid-desktop" || exit 1
    if [ -z "$PROVISION_FAIL" ]; then touch "$chroot_dir/.udroid-plasma-ready"; fi
}
do_compress() { touch "$1.tar.gz"; }
do_unmount() { :; }
""")
            result = subprocess.run(
                ["bash", str(ROOT / f"suites/{suite}/plasma/plasma.sh"), architecture],
                cwd=cook, capture_output=True, text=True,
                env={**os.environ, "RECORD": str(record), "PROVISION_FAIL": provision_fail},
            )
            sources = record.read_text() if record.exists() else ""
            archives = [path.name for path in cook.glob("out/*.tar.gz")]
            return result, sources, archives

    def test_debian_sources_overlay_and_archive_name(self):
        result, sources, archives = self.run_build("trixie")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("https://deb.debian.org/debian trixie main", sources)
        self.assertIn("trixie-updates", sources)
        self.assertIn("https://security.debian.org/debian-security trixie-security", sources)
        self.assertNotIn("ubuntu", sources)
        self.assertEqual(archives, ["trixie-plasma-arm64.tar.gz"])

    def test_ubuntu_keeps_its_sources_and_archive_name(self):
        result, sources, archives = self.run_build("resolute")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("resolute main restricted universe multiverse", sources)
        self.assertIn("resolute-security", sources)
        self.assertNotIn("debian", sources)
        self.assertEqual(archives, ["resolute-plasma-arm64.tar.gz"])

    def test_failed_provisioning_and_unsupported_architecture_never_pack(self):
        for options in ({"provision_fail": "1"}, {"architecture": "armhf"}):
            with self.subTest(options=options):
                result, _, archives = self.run_build("trixie", **options)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(archives, [])

    def test_matrix_and_release_metadata_recognize_trixie(self):
        matrix = json.loads(subprocess.check_output(
            [sys.executable, "gen_data/gen-suite-matrix.py"], cwd=ROOT, text=True,
        ))["include"]
        self.assertEqual([row for row in matrix if row["suite"] == "trixie"], [
            {"suite": "trixie", "variant": "plasma", "architecture": "arm64"},
        ])
        sys.path.insert(0, str(ROOT / "gen_data"))
        try:
            with mock.patch("utils.Popen", return_value="unused"):
                release = runpy.run_path(str(ROOT / "gen_data/gen-update-json.py"))
        finally:
            sys.path.pop(0)
        name = "trixie-plasma-arm64.tar.gz"
        self.assertEqual(release["strip_info"](name), ["trixie", "plasma", "aarch64", name])

    def test_catalogue_uses_os_release_from_completed_archives(self):
        sys.path.insert(0, str(ROOT / "gen_data"))
        try:
            import utils
            with tempfile.TemporaryDirectory() as directory:
                archive_path = Path(directory) / "sid-raw-arm64.tar.gz"
                with tarfile.open(archive_path, "w:gz") as archive:
                    link = tarfile.TarInfo("/etc/os-release")
                    link.type = tarfile.SYMTYPE
                    link.linkname = "../usr/lib/os-release"
                    archive.addfile(link)
                    release = b"NAME=Debian GNU/Linux\nID=debian\n"
                    file = tarfile.TarInfo("/usr/lib/os-release")
                    file.size = len(release)
                    archive.addfile(file, io.BytesIO(release))
                distribution = utils.distribution_from_archive(str(archive_path))
                self.assertEqual(distribution, "debian")
                generated = utils.resolv_data({"suites": []}, "sid", "raw", [], distribution)
                generated = utils.resolv_data(generated, "trixie", "gnome", [], distribution)
                self.assertEqual(generated["sid"]["distribution"], "debian")
                self.assertEqual(generated["trixie"]["distribution"], "debian")
                with self.assertRaises(ValueError):
                    utils.resolv_data(generated, "trixie", "plasma", [], "ubuntu")

                ubuntu_path = Path(directory) / "resolute-raw-arm64.tar.gz"
                with tarfile.open(ubuntu_path, "w:gz") as archive:
                    release = b'NAME=Ubuntu\nID="ubuntu"\n'
                    file = tarfile.TarInfo("/etc/os-release")
                    file.size = len(release)
                    archive.addfile(file, io.BytesIO(release))
                self.assertEqual(utils.distribution_from_archive(str(ubuntu_path)), "ubuntu")
        finally:
            sys.path.pop(0)

    def test_os_release_requires_a_valid_id(self):
        sys.path.insert(0, str(ROOT / "gen_data"))
        try:
            import utils
            with tempfile.TemporaryDirectory() as directory:
                archive_path = Path(directory) / "image.tar.gz"
                with tarfile.open(archive_path, "w:gz") as archive:
                    release = b"NAME=Ubuntu\nID_LIKE=debian\n"
                    file = tarfile.TarInfo("/etc/os-release")
                    file.size = len(release)
                    archive.addfile(file, io.BytesIO(release))
                with self.assertRaises(ValueError):
                    utils.distribution_from_archive(str(archive_path))
        finally:
            sys.path.pop(0)


if __name__ == "__main__":
    unittest.main()
