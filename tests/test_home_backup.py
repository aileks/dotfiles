import fcntl
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "bin/home-backup"
NOW = 1_800_000_000


class HomeBackupTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="home-backup-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.config = self.home / ".config"
        self.config.mkdir(parents=True)
        (self.config / "rsync-home.excludes").touch()
        self.state = self.home / ".local/state/home-backup"
        self.state.mkdir(parents=True)
        self.mount = self.root / "mounts/External"
        self.backups = self.mount / "Backups" / os.uname().nodename
        self.backups.mkdir(parents=True)
        self.commands = self.root / "bin"
        self.commands.mkdir()
        self.command("mountpoint", 'test -d "${@: -1}"')
        self.command("desktop-feedback", "exit 0")
        self.command("date", 'exec /usr/bin/date --date="@$BACKUP_TEST_TIME" "$@"')
        self.command("rsync", '''
printf '%s\\n' "$@" >"$BACKUP_TEST_ARGS"
if [[ ${BACKUP_TEST_FAIL:-0} == 1 ]]; then
  echo 'fixture rsync failure' >&2
  exit 23
fi
printf 'fixture content\\n' >"${@: -1}/copied-file"
''')
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.config),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "BACKUP_MOUNT_BASE": str(self.root / "mounts"),
            "BACKUP_LABEL": "External",
            "BACKUP_TEST_TIME": str(NOW),
            "BACKUP_TEST_ARGS": str(self.root / "rsync-args"),
            "PATH": f"{self.commands}:/usr/bin:/bin",
        }

    def command(self, name, body):
        path = self.commands / name
        path.write_text("#!/usr/bin/env bash\nset -eu\n" + body + "\n")
        path.chmod(0o700)

    def run_backup(self, *arguments, expected_exit=0):
        result = subprocess.run(
            [str(SCRIPT), *arguments], env=self.env, capture_output=True,
            text=True, timeout=5,
        )
        self.assertEqual(result.returncode, expected_exit, result.stderr)
        return result

    def set_success(self, timestamp):
        (self.state / "last-success").write_text(f"{timestamp}\n")

    def test_recent_success_skips_without_changing_status(self):
        self.set_success(NOW - 86399)
        status = self.state / "status"
        status.write_text("previous complete\n")
        self.run_backup("--if-due")
        self.assertFalse((self.root / "rsync-args").exists())
        self.assertEqual(status.read_text(), "previous complete\n")

    def test_due_backup_completes_and_next_check_skips(self):
        self.set_success(NOW - 86400)
        self.run_backup("--if-due")
        latest = self.backups / "latest"
        self.assertEqual((latest / "copied-file").read_text(), "fixture content\n")
        self.assertEqual((self.state / "last-success").read_text(), f"{NOW}\n")
        arguments = self.root / "rsync-args"
        self.assertNotIn("--info=progress2", arguments.read_text())
        arguments.unlink()
        self.run_backup("--if-due")
        self.assertFalse(arguments.exists())

    def test_existing_latest_initializes_success_from_link_mtime(self):
        snapshot = self.backups / "snapshots/2026-09-13T193654Z"
        snapshot.mkdir(parents=True)
        os.utime(snapshot, (0, 0))
        latest = self.backups / "latest"
        latest.symlink_to(snapshot)
        os.utime(latest, (NOW - 60, NOW - 60), follow_symlinks=False)
        self.run_backup("--if-due")
        self.assertEqual((self.state / "last-success").read_text(), f"{NOW - 60}\n")
        self.assertFalse((self.root / "rsync-args").exists())

    def test_unavailable_drive_is_logged_and_retried(self):
        old_success = NOW - 86400
        self.set_success(old_success)
        self.env["BACKUP_LABEL"] = "Disconnected"
        self.run_backup("--if-due", expected_exit=1)
        self.assertIn("unavailable", (self.state / "status").read_text())
        self.assertIn("Backup mount not available", (self.state / "scheduled.log").read_text())
        self.assertEqual((self.state / "last-success").read_text(), f"{old_success}\n")
        self.env["BACKUP_LABEL"] = "External"
        self.run_backup("--if-due")
        self.assertEqual((self.state / "last-success").read_text(), f"{NOW}\n")

    def test_rsync_failure_preserves_success_and_retries(self):
        old_success = NOW - 86400
        self.set_success(old_success)
        self.env["BACKUP_TEST_FAIL"] = "1"
        self.run_backup("--if-due", expected_exit=23)
        self.assertIn("failed", (self.state / "status").read_text())
        self.assertIn("fixture rsync failure", (self.state / "scheduled.log").read_text())
        self.assertEqual((self.state / "last-success").read_text(), f"{old_success}\n")
        self.assertFalse((self.backups / "latest").exists())
        self.env["BACKUP_TEST_FAIL"] = "0"
        self.run_backup("--if-due")
        self.assertTrue((self.backups / "latest/copied-file").exists())

    def test_manual_backup_runs_even_when_recent(self):
        self.set_success(NOW - 60)
        self.run_backup()
        self.assertEqual((self.state / "last-success").read_text(), f"{NOW}\n")
        self.assertIn("--info=progress2", (self.root / "rsync-args").read_text())

    def test_existing_lock_blocks_manual_and_scheduled_backup(self):
        with (self.state / "home-backup.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            self.run_backup()
            self.run_backup("--if-due")
        self.assertFalse((self.root / "rsync-args").exists())

    def test_scheduled_log_rotates_before_attempt(self):
        log = self.state / "scheduled.log"
        log.write_text("x" * (1048576 + 1))
        self.run_backup("--if-due")
        self.assertEqual((self.state / "scheduled.log.1").stat().st_size, 1048577)
        self.assertIn("Backup complete", log.read_text())


if __name__ == "__main__":
    unittest.main()
