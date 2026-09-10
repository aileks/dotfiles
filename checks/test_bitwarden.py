"""Only fake CLI responses, never connect to a real vault or browser."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

source = Path(__file__).resolve().parents[1] / "config/qutebrowser/bitwarden.py"
spec = importlib.util.spec_from_file_location("bitwarden", source)
bw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bw)
LOGIN = {"id": "test-uuid", "name": "Harmless example", "login": {
    "username": "example", "password": "not-a-real-password",
    "uris": [{"uri": "https://example.com", "match": 0}],
}}


class LookupTests(unittest.TestCase):
    def test_cli_is_authoritative_for_subdomain_and_deduplicates(self):
        with patch.object(bw, "vault_command", return_value=json.dumps([LOGIN, LOGIN])), patch.object(bw, "menu", return_value=0), patch.object(bw, "sync_vault") as sync:
            self.assertEqual(bw.choose_login("https://accounts.example.com/login", "key", "session"), LOGIN)
            sync.assert_not_called()

    def test_sync_on_miss_retries_same_url(self):
        with patch.object(bw, "vault_command", side_effect=["[]", json.dumps([LOGIN])]) as command, patch.object(bw, "sync_vault") as sync, patch.object(bw, "menu", return_value=0):
            url = "https://accounts.example.com/"
            self.assertEqual(bw.choose_login(url, "key", "session"), LOGIN)
            self.assertEqual(command.call_args_list[0], command.call_args_list[1])
            sync.assert_called_once_with("session")

    def test_manual_search_requires_opt_in_and_second_confirmation(self):
        with patch.object(bw, "url_matches", return_value=[]), patch.object(bw, "sync_vault"), patch.object(bw, "manual_matches", return_value=[LOGIN]) as search, patch.object(bw, "menu", side_effect=[1, 0, 0]):
            with self.assertRaises(bw.Cancelled):
                bw.choose_login("https://example.com/", "key", "session")
            search.assert_called_once()

    def test_cancel_does_not_search(self):
        with patch.object(bw, "url_matches", return_value=[]), patch.object(bw, "sync_vault"), patch.object(bw, "manual_matches") as search, patch.object(bw, "menu", return_value=0):
            with self.assertRaises(bw.Cancelled):
                bw.choose_login("https://example.com/", "key", "session")
            search.assert_not_called()

    def test_failed_network_sync_preserves_key_and_rate_limits(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {"XDG_RUNTIME_DIR": directory}), patch.object(bw, "run", return_value=SimpleNamespace(returncode=1)) as run, patch.object(bw, "qute_command"):
            self.assertTrue(bw.sync_vault("session"))
            self.assertFalse(bw.sync_vault("session"))
            self.assertEqual(run.call_count, 1)
            self.assertEqual(run.call_args.args[0][1], "sync")

    def test_locked_session_is_revoked(self):
        with patch.object(bw, "run", side_effect=[
            SimpleNamespace(returncode=1), SimpleNamespace(returncode=0, stdout='{"status":"locked"}'),
            SimpleNamespace(returncode=0),
        ]) as run:
            with self.assertRaises(bw.VaultError):
                bw.vault_command(["list", "items"], "key", "session")
            self.assertEqual(run.call_args.args[0], ["keyctl", "revoke", "key"])

    def test_malformed_response_has_controlled_error(self):
        for text in ("secret-not-json", "{}", "null"):
            with self.assertRaises(bw.VaultError) as caught:
                bw.login_entries(text)
            self.assertNotIn("secret-not-json", str(caught.exception))

    def test_saved_uri_menu_omits_private_url_components(self):
        entry = {"login": {"uris": [{"uri": "https://user:secret@lab.example.com:8443/private?token=secret#secret", "match": 1}]}}
        self.assertEqual(bw.saved_hosts(entry), "lab.example.com:8443 [host]")

    def test_non_http_urls_are_rejected(self):
        for url in ("file:///tmp/login", "qute://settings", "https://", "https://example.com:invalid"):
            self.assertIsNone(bw.origin(url))


if __name__ == "__main__":
    unittest.main()
