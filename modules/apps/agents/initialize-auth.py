"""Initialize coding agent authentication from runtime SOPS secrets."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile


def read_object(path):
    try:
        value = json.loads(path.read_text())
        if not isinstance(value, dict):
            raise ValueError()
        return value
    except (ValueError, UnicodeError):
        # Never include credential contents in activation logs.
        raise ValueError(f"Invalid credential JSON: {path}") from None


def write_private(path, content):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.parent.chmod(0o700)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as output:
            output.write(content)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def seed_login(destination, credential):
    if destination.is_symlink():
        raise ValueError(f"Login cache must be writable, not a symlink: {destination}")
    serialized = json.dumps(credential, sort_keys=True, separators=(",", ":"))
    fingerprint = hashlib.sha256(serialized.encode()).hexdigest()
    marker = destination.with_name(".auth-seed.sha256")
    previous = marker.read_text().strip() if marker.exists() else None

    # Adopt existing logins on first activation. Keep refreshed credentials on
    # subsequent boots; replace them only when the encrypted seed changes.
    if not destination.exists() or (previous is not None and previous != fingerprint):
        write_private(destination, json.dumps(credential, indent=2) + "\n")
    else:
        destination.parent.chmod(0o700)
        destination.chmod(0o600)
    write_private(marker, fingerprint + "\n")


def initialize(home, codex_auth, cursor_auth, deepseek_key, openrouter_key, cursor_dir=None):
    home = Path(home)
    codex = read_object(Path(codex_auth))
    cursor = read_object(Path(cursor_auth))
    pi_path = home / ".pi/agent/auth.json"
    pi = read_object(pi_path) if pi_path.exists() else {}
    for provider, path in (("deepseek", deepseek_key), ("openrouter", openrouter_key)):
        key = Path(path).read_text().strip()
        if not key:
            raise ValueError(f"Empty provider secret: {path}")
        pi[provider] = {"type": "api_key", "key": key}

    seed_login(home / ".codex/auth.json", codex)
    cursor_dir = Path(cursor_dir) if cursor_dir else home / ".config/cursor"
    seed_login(cursor_dir / "auth.json", cursor)

    content = json.dumps(pi, indent=2) + "\n"
    # Replace any previous template symlink with a private, writable file.
    if pi_path.is_symlink() or not pi_path.exists() or pi_path.read_text() != content:
        write_private(pi_path, content)
    else:
        pi_path.parent.chmod(0o700)
        pi_path.chmod(0o600)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("home", "codex-auth", "cursor-auth", "deepseek-key", "openrouter-key"):
        parser.add_argument(f"--{name}", required=True)
    parser.add_argument("--cursor-dir")
    arguments = parser.parse_args()
    try:
        initialize(**vars(arguments))
    except (OSError, ValueError) as error:
        parser.exit(1, f"Agent credential initialization failed: {error}\n")


if __name__ == "__main__":
    main()
