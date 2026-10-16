import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


INSTALLER = Path(__file__).resolve().parents[1] / (
    "shared/plasma/plasma-overlay/usr/local/libexec/udroid/install-chromium"
)


class ChromiumInstallerTest(unittest.TestCase):
    def run_installer(self, distro="ubuntu", **overrides):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            release = root / "os-release"
            release.write_text(f"ID={distro}\n")
            installer = root / "installer.sh"
            installer.write_text(INSTALLER.read_text().replace(
                ". /etc/os-release", '. "$TEST_OS_RELEASE"',
            ))
            log = root / "commands.jsonl"
            stub = root / "stub"
            stub.write_text("""#!/usr/bin/env python3
import json, os, pathlib, sys
command = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['COMMAND_LOG'], 'a') as log:
    log.write(json.dumps([command, *args]) + '\\n')
if command == 'dpkg':
    print(os.environ.get('ARCH', 'arm64'))
elif command == 'apt-cache':
    print('  Candidate: ' + os.environ.get('CANDIDATE', '155.0-test'))
elif command == 'apt-get':
    if os.environ.get('FAIL_STAGE') in args:
        sys.exit(100)
    if 'download' in args:
        for package in args[args.index('download') + 1:]:
            pathlib.Path(package.split('=')[0] + '_test_arm64.deb').touch()
""")
            stub.chmod(0o755)
            for command in ("dpkg", "apt-get", "apt-cache", "dpkg-query"):
                (root / command).symlink_to(stub)
            result = subprocess.run(
                ["sh", str(installer)], capture_output=True, text=True,
                env={**os.environ, "PATH": f"{root}:{os.environ['PATH']}",
                     "COMMAND_LOG": str(log), "TMPDIR": str(root),
                     "TEST_OS_RELEASE": str(release), **overrides},
            )
            commands = [json.loads(line) for line in log.read_text().splitlines()]
            leftovers = [path for path in root.iterdir() if path.is_dir()]
            self.assertEqual(leftovers, [], "temporary APT metadata was not cleaned up")
            return result, commands

    def test_downloads_matching_versions_with_isolated_metadata(self):
        result, commands = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stderr)
        download = next(args for args in commands if "download" in args)
        self.assertIn("chromium=155.0-test", download)
        self.assertIn("chromium-common=155.0-test", download)
        self.assertIn("libjpeg62-turbo", download)
        self.assertIn("Dir::Etc::sourceparts=-", download)
        installs = [args for args in commands if "install" in args]
        self.assertEqual(len(installs), 2)
        self.assertFalse(any(arg.startswith("Dir::") for arg in installs[-1]))
        self.assertEqual(sum(arg.endswith(".deb") for arg in installs[-1]), 3)

    def test_debian_uses_only_native_apt_packages(self):
        result, commands = self.run_installer(distro="debian")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(commands, [[
            "apt-get", "install", "-y", "--no-install-recommends", "chromium",
        ]])

    def test_failures_never_reach_package_installation(self):
        for overrides in ({"FAIL_STAGE": "update"}, {"FAIL_STAGE": "download"},
                          {"CANDIDATE": "(none)"}, {"CANDIDATE": ""}):
            with self.subTest(overrides=overrides):
                result, commands = self.run_installer(**overrides)
                self.assertNotEqual(result.returncode, 0)
                installs = [args for args in commands if "install" in args]
                self.assertEqual(len(installs), 1)  # Only the archive keyring.

    def test_rejects_unsupported_architecture_before_installing(self):
        result, commands = self.run_installer(ARCH="amd64")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(commands, [["dpkg", "--print-architecture"]])


if __name__ == "__main__":
    unittest.main()
