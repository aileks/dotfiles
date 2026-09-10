# SPDX-FileCopyrightText: Chris Braun (cryzed) <cryzed@googlemail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
"""Adapted from qutebrowser v3.7.0's qute-bitwarden userscript.

Run `bw login` once in a terminal. Sessions stay in the kernel keyring for
15 minutes; filling uses a private file instead of logged fake-key commands.
"""

import argparse
from datetime import datetime
import fcntl
import json
import os
import re
from pathlib import Path
import shlex
import shutil
import signal
import stat
import subprocess
import tempfile
import time
from urllib.parse import unquote, urlsplit


KEY_NAME = "qutebrowser-bitwarden-session"
LOCK_SECONDS = 900


class Cancelled(Exception):
    pass


class VaultError(Exception):
    pass


def run(command, *, stdin=None, env=None, timeout=30):
    return subprocess.run(
        command,
        input=stdin,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        timeout=timeout,
        check=False,
    )


def qute_command(command):
    # A browser which has exited must not leave us blocked opening its FIFO.
    fd = os.open(os.environ["QUTE_FIFO"], os.O_WRONLY | os.O_NONBLOCK)
    with os.fdopen(fd, "w", encoding="utf-8") as fifo:
        fifo.write(command + "\n")


def unlock_password():
    reply = run(
        ["pinentry-gnome3"],
        stdin=(
            "SETTITLE Bitwarden\n"
            "SETDESC Unlock Bitwarden for qutebrowser\n"
            "SETPROMPT Master password:\nGETPIN\nBYE\n"
        ),
        timeout=120,
    )
    for line in reply.stdout.splitlines():
        if line.startswith("D "):
            return unquote(line[2:])
    raise Cancelled


def session_key():
    existing = run(["keyctl", "search", "@s", "user", KEY_NAME])
    if existing.returncode == 0:
        key_id = existing.stdout.strip()
        cached = run(["keyctl", "pipe", key_id])
        if cached.returncode == 0 and cached.stdout:
            return key_id, cached.stdout

    status = run(["bw", "status"])
    if status.returncode != 0 or decode_object(status.stdout).get("status") == "unauthenticated":
        raise VaultError("Run bw login in a terminal first")
    unlocked = run(
        ["bw", "unlock", "--raw", "--passwordenv", "BW_MASTERPASS", "--nointeraction"],
        env={**os.environ, "BW_MASTERPASS": unlock_password()},
        timeout=60,
    )
    if unlocked.returncode != 0 or not unlocked.stdout.strip():
        raise VaultError("Could not unlock the vault")
    session = unlocked.stdout.strip()
    # padd reads the key payload from stdin, unlike keyctl add's argv payload.
    # The session keyring gives child processes possession and expiry rights.
    stored = run(["keyctl", "padd", "user", KEY_NAME, "@s"], stdin=session)
    if stored.returncode != 0:
        raise VaultError("Could not cache the session in the kernel keyring")
    key_id = stored.stdout.strip()
    if run(["keyctl", "timeout", key_id, str(LOCK_SECONDS)]).returncode != 0:
        run(["keyctl", "revoke", key_id])
        raise VaultError("Could not set the session expiry")
    return key_id, session


def vault_command(arguments, key_id, session):
    result = run(
        ["bw", *arguments, "--nointeraction"],
        env={**os.environ, "BW_SESSION": session},
    )
    if result.returncode != 0:
        status = run(["bw", "status"], env={**os.environ, "BW_SESSION": session})
        if status.returncode == 0 and decode_object(status.stdout).get("status") in ("locked", "unauthenticated"):
            run(["keyctl", "revoke", key_id])
            raise VaultError("Vault is locked; retry to unlock again")
        raise VaultError("Vault request failed; the cached session was preserved")
    return result.stdout


def decode_object(text):
    try:
        result = json.loads(text)
    except (ValueError, TypeError):
        raise VaultError("Bitwarden returned malformed JSON") from None
    if not isinstance(result, dict):
        raise VaultError("Bitwarden returned an unexpected response")
    return result


def private_runtime():
    runtime = Path(os.environ["XDG_RUNTIME_DIR"])
    permissions = runtime.stat()
    if runtime.is_symlink() or permissions.st_uid != os.getuid() or stat.S_IMODE(permissions.st_mode) != 0o700:
        raise VaultError("XDG_RUNTIME_DIR must be private to your user")
    directory = runtime / "qute-bitwarden"
    directory.mkdir(mode=0o700, exist_ok=True)
    permissions = directory.lstat()
    if not stat.S_ISDIR(permissions.st_mode) or permissions.st_uid != os.getuid() or stat.S_IMODE(permissions.st_mode) != 0o700:
        raise VaultError("Bitwarden runtime directory must be private to your user")
    return directory


def sync_vault(session, *, automatic=True):
    directory = private_runtime()
    # Serialize the timestamp decision across simultaneous browser bindings.
    with (directory / "sync.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        timestamp = directory / "last-sync-attempt"
        try:
            previous = float(timestamp.read_text())
        except (FileNotFoundError, ValueError):
            previous = 0
        now = time.time()
        if automatic and 0 <= now - previous < 60:
            return False
        timestamp.write_text(str(now))
        try:
            result = run(["bw", "sync", "--nointeraction"], env={**os.environ, "BW_SESSION": session}, timeout=60)
            succeeded = result.returncode == 0
        except subprocess.TimeoutExpired:
            succeeded = False
        if not succeeded:
            qute_command("message-warning " + shlex.quote("Could not synchronize Bitwarden; using local vault"))
        return True


def login_entries(text):
    try:
        entries = json.loads(text)
    except (ValueError, TypeError):
        raise VaultError("Bitwarden returned malformed JSON") from None
    if not isinstance(entries, list):
        raise VaultError("Bitwarden returned an unexpected candidate list")
    matches = {}
    for entry in entries:
        if isinstance(entry, dict) and isinstance(entry.get("login"), dict) and isinstance(entry.get("id"), str):
            matches.setdefault(entry["id"], entry)
    return list(matches.values())


def origin(url):
    try:
        parsed = urlsplit(url)
        if parsed.scheme not in ("http", "https") or not parsed.hostname:
            return None
        return parsed.scheme, parsed.hostname.lower(), parsed.port or (443 if parsed.scheme == "https" else 80)
    except ValueError:
        return None


def url_matches(url, key_id, session):
    # Bitwarden owns all URI match modes, including the account default.
    return login_entries(vault_command(["list", "items", "--url", url], key_id, session))


def menu(prompt, labels):
    choice = run(["wmenu", "-i", "-p", prompt], stdin="\n".join(labels), timeout=120)
    if choice.returncode != 0 or choice.stdout.rstrip("\n") not in labels:
        raise Cancelled
    return labels.index(choice.stdout.rstrip("\n"))


def safe_label(value):
    return "".join(char if char.isprintable() else " " for char in str(value or ""))


def saved_hosts(entry):
    modes = {0: "domain", 1: "host", 2: "starts with", 3: "exact", 4: "regex", 5: "never"}
    hosts = []
    for saved in entry["login"].get("uris") or []:
        if not isinstance(saved, dict):
            continue
        # Regex patterns are not URLs and may contain private path/query data.
        if saved.get("match") == 4:
            hosts.append("[regex]")
            continue
        value = saved.get("uri")
        if not isinstance(value, str):
            continue
        try:
            parsed = urlsplit(value if "://" in value else "//" + value)
            host = parsed.hostname
            if host:
                if ":" in host:
                    host = "[" + host + "]"
                port = f":{parsed.port}" if parsed.port is not None else ""
                hosts.append(safe_label(host + port) + " [" + modes.get(saved.get("match"), "default") + "]")
        except ValueError:
            continue
    return ", ".join(dict.fromkeys(hosts))[:240] or "(no usable URI)"


def manual_matches(url, key_id, session):
    try:
        import tldextract
    except ImportError:
        raise VaultError("Manual search requires the tldextract Python package") from None
    hostname = urlsplit(url).hostname
    extracted = tldextract.TLDExtract(suffix_list_urls=())(hostname)
    domain = extracted.top_domain_under_public_suffix
    terms = list(dict.fromkeys(term for term in (hostname, domain) if term))
    matches = {}
    for term in terms:
        for entry in login_entries(vault_command(["list", "items", "--search", term], key_id, session)):
            matches.setdefault(entry["id"], entry)
    return list(matches.values())


def choose_login(url, key_id, session):
    matches = url_matches(url, key_id, session)
    if not matches:
        sync_vault(session)
        matches = url_matches(url, key_id, session)
    manual = not matches
    if manual:
        if menu(f"Bitwarden: no URI match for {safe_label(urlsplit(url).hostname)} - search vault manually?",
                ["Cancel", "Search vault manually"]) != 1:
            raise Cancelled
        matches = manual_matches(url, key_id, session)
    if not matches:
        raise VaultError("No login found in the local vault")
    labels = [
        f"{'[manual] ' if manual else ''}{index + 1}: {safe_label(entry.get('name'))} | "
        f"{safe_label(entry['login'].get('username'))} | {saved_hosts(entry)}"
        for index, entry in enumerate(matches)
    ]
    selected = matches[menu("Bitwarden", labels)]
    if manual and menu("Saved URI does not match this page according to Bitwarden. Fill anyway?",
                       ["Cancel", "Fill selected login"]) != 1:
        raise Cancelled
    return selected


def diagnose(url):
    # Fixed fields only. Never show vault entries, URL paths or raw command output.
    scheme, host, _port = origin(url)
    report = [f"Page: {safe_label(scheme)}://{safe_label(host)}"]
    for executable in ("bw", "keyctl", "pinentry-gnome3", "wmenu", "rm", "python3"):
        report.append(f"{executable}: {'present' if shutil.which(executable) else 'missing'}")
    status = run(["bw", "status"])
    if status.returncode == 0:
        status_values = decode_object(status.stdout)
        state = status_values.get("status")
        if state in ("locked", "unlocked", "unauthenticated"):
            report.append("Vault: " + state)
        try:
            last_sync = datetime.fromisoformat(status_values.get("lastSync", ""))
            report.append("Last sync: " + last_sync.isoformat())
        except (TypeError, ValueError):
            pass
    version = run(["bw", "--version"])
    if version.returncode == 0 and re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version.stdout.strip()):
        report.append("CLI version: " + version.stdout.strip())
    key_id, session = session_key()
    before = url_matches(url, key_id, session)
    report.append(f"URI candidates before sync: {len(before)}")
    attempted = False
    if not before:
        attempted = sync_vault(session)
        after = url_matches(url, key_id, session)
        report.append(f"URI candidates after sync: {len(after)}")
    report.append(f"Automatic sync attempted: {attempted}")
    report.append("No fill performed")
    qute_command("message-info " + shlex.quote("; ".join(report)))


def fill_login(payload):
    runtime = private_runtime()
    template = Path(__file__).with_name("fill.js").read_text(encoding="utf-8")
    with tempfile.TemporaryDirectory(prefix="qute-bitwarden-", dir=runtime) as directory:
        path = Path(directory) / "fill.js"
        with path.open("x", encoding="utf-8") as output:
            os.chmod(path, 0o600)
            output.write(template.replace("/*__LOGIN__*/", json.dumps(payload, ensure_ascii=True)))
        # jseval reads the file synchronously before the next command can run.
        # Keep a 30-second fallback for browser exit or an interrupted command.
        qute_command("\n".join([
            "jseval --file --quiet " + shlex.quote(str(path)),
            "spawn -- " + shlex.quote(shutil.which("rm")) + " -- " + shlex.quote(str(path)),
        ]))
        deadline = time.monotonic() + 30
        while path.exists() and time.monotonic() < deadline:
            time.sleep(0.1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--username-only", action="store_true")
    modes.add_argument("--password-only", action="store_true")
    modes.add_argument("--totp-only", action="store_true")
    modes.add_argument("--sync", action="store_true")
    modes.add_argument("--diagnose", action="store_true")
    args = parser.parse_args()
    os.umask(0o077)
    url = os.environ.get("QUTE_URL", "")
    if not origin(url):
        raise VaultError("Open an HTTP or HTTPS login page first")
    private_runtime()
    if args.diagnose:
        diagnose(url)
        return
    key_id, session = session_key()
    if args.sync:
        sync_vault(session, automatic=False)
        return
    selected = choose_login(url, key_id, session)
    mode = "login"
    credentials = selected["login"]
    if args.totp_only:
        mode = "totp"
        if not credentials.get("totp"):
            raise VaultError("This login has no TOTP configured")
        value = vault_command(["get", "totp", selected["id"]], key_id, session).strip()
    elif args.username_only:
        mode, value = "username", credentials.get("username") or ""
    elif args.password_only:
        mode, value = "password", credentials.get("password") or ""
    else:
        value = {
            "username": credentials.get("username") or "",
            "password": credentials.get("password") or "",
        }
    fill_login({"url": url, "mode": mode, "value": value})


def interrupted(_signal, _frame):
    raise Cancelled


if __name__ == "__main__":
    for signum in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(signum, interrupted)
    try:
        main()
    except Cancelled:
        pass
    except Exception as error:
        # Never echo subprocess output, credential values, or a traceback.
        reason = str(error) if isinstance(error, VaultError) else "Request failed or timed out"
        try:
            qute_command("message-error " + shlex.quote("Bitwarden: " + reason))
        except OSError:
            pass
