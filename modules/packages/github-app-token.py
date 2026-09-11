#!/usr/bin/env python3
"""Mint a GitHub App installation access token.

No third-party dependencies required at the CLI level: signing prefers the
`cryptography` / PyJWT modules when importable (they ship with the Hermes
runtime), and otherwise shells out to the `openssl` binary.

Config (non-secret) lives in ~/.hermes/gh-app.json:

    {
      "app_id": "123456",
      "installation_id": "7891011",
      "key_ref": "op://Mira / Flint Workshop/GitHub App - Mira Virellia/credential",
      "key_file": null
    }

`key_ref` is an `op read` reference (preferred). `key_file` is a local path
fallback. The key is never printed, cached, or written outside a 0600 temp
file that is unlinked immediately.

Usage:
    gh-app-token.py              # print token
    gh-app-token.py --export     # print `export GH_TOKEN=...`
    gh-app-token.py --write-env  # write ~/.hermes/gh-app.env (mode 0600)
    gh-app-token.py --status     # show cache state
    gh-app-token.py --json       # non-secret fields of a fresh mint response
"""

from __future__ import annotations

import base64
import calendar
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

HOME = pathlib.Path(os.environ.get("HERMES_HOME") or pathlib.Path.home() / ".hermes")
CONFIG = HOME / "gh-app.json"
CACHE = HOME / "gh-app-token.json"
ENVFILE = HOME / "gh-app.env"
API = "https://api.github.com"
REFRESH_SKEW = 300  # re-mint when fewer than 5 minutes remain
JWT_LIFETIME = 540  # GitHub rejects anything over 600s


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def load_config() -> dict:
    if not CONFIG.exists():
        sys.exit(f"missing config: {CONFIG}")
    cfg = json.loads(CONFIG.read_text())
    if not cfg.get("key_ref") and not cfg.get("key_file"):
        sys.exit(f"config needs key_ref or key_file: {CONFIG}")
    return cfg


def require_ids(cfg: dict, need: tuple[str, ...] = ("app_id", "installation_id")) -> None:
    missing = [f for f in need if not cfg.get(f)]
    if missing:
        sys.exit(f"config missing {', '.join(repr(m) for m in missing)}: {CONFIG}")


def normalize_pem(text: str) -> str:
    """Re-wrap a PEM block that lost its line breaks in transit.

    Pasting a key into a 1Password password field, a chat box or a shell
    variable can collapse newlines into spaces. PEM parsers want the base64
    body on its own 64-column lines, so rebuild it from the armour markers.
    """
    import re

    match = re.search(
        r"-----BEGIN ([A-Z0-9 ]+)-----(.*?)-----END \1-----",
        text,
        re.DOTALL,
    )
    if not match:
        return text  # let the parser produce the real error
    label, body = match.group(1), match.group(2)
    b64 = "".join(body.split())
    lines = [b64[i : i + 64] for i in range(0, len(b64), 64)]
    return f"-----BEGIN {label}-----\n" + "\n".join(lines) + f"\n-----END {label}-----\n"


def read_key(cfg: dict) -> str:
    if cfg.get("key_ref"):
        try:
            out = subprocess.run(
                ["op", "read", cfg["key_ref"]],
                check=True,
                capture_output=True,
                text=True,
            )
        except FileNotFoundError:
            sys.exit("`op` not found in PATH; install the 1Password CLI")
        except subprocess.CalledProcessError as exc:
            sys.exit(f"op read failed: {exc.stderr.strip()}")
        return normalize_pem(out.stdout)
    path = pathlib.Path(cfg["key_file"]).expanduser()
    if not path.exists():
        sys.exit(f"key file not found: {path}")
    return normalize_pem(path.read_text())


def _sign_python(signing_input: bytes, key_pem: str) -> bytes | None:
    """RS256 via `cryptography`, if available."""
    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import padding
    except ImportError:
        return None
    key = serialization.load_pem_private_key(key_pem.encode(), password=None)
    return key.sign(signing_input, padding.PKCS1v15(), hashes.SHA256())


def _sign_openssl(signing_input: bytes, key_pem: str) -> bytes | None:
    """RS256 via the `openssl` binary, if available.

    openssl wants the key on disk, so hand it an ephemeral 0600 file.
    """
    exe = shutil.which("openssl")
    if exe is None:
        return None
    fd, path = tempfile.mkstemp(prefix="gh-app-", suffix=".pem")
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w") as fh:
            fh.write(key_pem)
        proc = subprocess.run(
            [exe, "dgst", "-sha256", "-sign", path],
            input=signing_input,
            capture_output=True,
        )
        if proc.returncode != 0:
            raise RuntimeError(proc.stderr.decode(errors="replace").strip())
        return proc.stdout
    finally:
        try:
            os.unlink(path)
        except OSError:
            pass


def sign_rs256(signing_input: bytes, key_pem: str) -> str:
    for backend in (_sign_python, _sign_openssl):
        sig = backend(signing_input, key_pem)
        if sig is not None:
            return b64url(sig)
    sys.exit(
        "no RS256 backend: neither the `cryptography` module nor the `openssl` "
        "binary is available"
    )


def app_jwt(app_id: str, key_pem: str) -> str:
    now = int(time.time())
    header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}, separators=(",", ":")).encode())
    payload = b64url(
        json.dumps(
            {"iat": now - 60, "exp": now + JWT_LIFETIME, "iss": app_id},
            separators=(",", ":"),
        ).encode()
    )
    signing_input = f"{header}.{payload}".encode()
    return f"{header}.{payload}.{sign_rs256(signing_input, key_pem)}"


def mint(cfg: dict, repos: list[str] | None = None) -> dict:
    jwt = app_jwt(cfg["app_id"], read_key(cfg))
    url = f"{API}/app/installations/{cfg['installation_id']}/access_tokens"
    body = json.dumps({"repositories": repos}).encode() if repos else b"{}"
    req = urllib.request.Request(url, data=body, method="POST")
    for name, value in (
        ("Authorization", f"Bearer {jwt}"),
        ("Accept", "application/vnd.github+json"),
        ("X-GitHub-Api-Version", "2022-11-28"),
        ("User-Agent", "mira-virellia-gh-app-token"),
        ("Content-Type", "application/json"),
    ):
        req.add_header(name, value)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        sys.exit(f"token mint failed: HTTP {exc.code}\n{detail}")


def cached() -> str | None:
    if not CACHE.exists():
        return None
    try:
        data = json.loads(CACHE.read_text())
    except (json.JSONDecodeError, OSError):
        return None
    if time.time() + REFRESH_SKEW < data.get("expires_epoch", 0):
        return data.get("token")
    return None


def store(resp: dict) -> None:
    # GitHub returns UTC ISO 8601. time.mktime would interpret it as local time,
    # which silently skews the cache by the UTC offset — use timegm instead.
    epoch = 0
    try:
        epoch = calendar.timegm(time.strptime(resp.get("expires_at", ""), "%Y-%m-%dT%H:%M:%SZ"))
    except ValueError:
        pass
    CACHE.write_text(json.dumps({**resp, "expires_epoch": epoch}))
    CACHE.chmod(0o600)


def app_request(path: str, cfg: dict, method: str = "GET", body: dict | None = None) -> object:
    jwt = app_jwt(str(cfg["app_id"]), read_key(cfg))
    req = urllib.request.Request(f"{API}{path}", data=json.dumps(body).encode() if body else None, method=method)
    for name, value in (
        ("Authorization", f"Bearer {jwt}"),
        ("Accept", "application/vnd.github+json"),
        ("X-GitHub-Api-Version", "2022-11-28"),
        ("User-Agent", "mira-virellia-gh-app-token"),
        ("Content-Type", "application/json"),
    ):
        req.add_header(name, value)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        sys.exit(f"{method} {path} failed: HTTP {exc.code}\n{detail}")


def discover(cfg: dict) -> list[dict]:
    """List the app's installations and record the id when unambiguous."""
    installs = app_request("/app/installations", cfg)
    if not isinstance(installs, list):
        sys.exit(f"unexpected response: {installs}")
    for inst in installs:
        acct = (inst.get("account") or {}).get("login")
        print(
            f"installation {inst['id']}: account={acct} "
            f"selection={inst.get('repository_selection')} "
            f"repos={inst.get('repository_selection') == 'all' and 'ALL' or 'selected'}"
        )
    if len(installs) == 1:
        cfg["installation_id"] = str(installs[0]["id"])
        CONFIG.write_text(json.dumps(cfg, indent=2) + "\n")
        print(f"recorded installation_id {cfg['installation_id']} in {CONFIG}")
    return installs


def key_summary(key_pem: str) -> dict:
    """Non-sensitive facts about a private key, for validation."""
    import hashlib
    import re

    try:
        from cryptography.hazmat.primitives import serialization
    except ImportError:
        return {"backend": "openssl-only", "note": "cryptography not importable"}
    key = serialization.load_pem_private_key(key_pem.encode(), password=None)
    pub = key.public_key().public_bytes(
        serialization.Encoding.DER,
        serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    label = re.search(r"-----BEGIN ([A-Z0-9 ]+)-----", key_pem)
    return {
        "backend": "cryptography",
        "type": type(key).__name__,
        "key_size": getattr(key, "key_size", None),
        "pem_label": label.group(1) if label else "?",
        "pubkey_sha256": hashlib.sha256(pub).hexdigest(),
    }


def main() -> None:
    args = sys.argv[1:]
    cfg = load_config()

    if "--discover" in args:
        require_ids(cfg, need=("app_id",))
        discover(cfg)
        return

    if "--check-key" in args:
        info = key_summary(read_key(cfg))
        print(f"config:  {CONFIG}")
        for field in ("backend", "type", "key_size", "pem_label", "pubkey_sha256", "note"):
            if info.get(field) is not None:
                print(f"{field}: {info[field]}")
        return

    if "--status" in args:
        print(f"config:  {CONFIG}")
        for field in ("app_id", "installation_id"):
            print(f"{field}: {cfg.get(field) or '(unset)'}")
        print(f"cache:   {CACHE} ({'present' if CACHE.exists() else 'absent'})")
        if CACHE.exists():
            data = json.loads(CACHE.read_text())
            left = int(data.get("expires_epoch", 0) - time.time())
            print(f"expires: {'in %ds' % left if left > 0 else 'expired %ds ago' % -left}")
        print(f"usable:  {'yes' if cached() else 'no (mint required)'}")
        return

    resp = None
    token = cached()
    if token is None:
        require_ids(cfg)
        resp = mint(cfg)
        store(resp)
        token = resp["token"]

    if "--json" in args:
        # Non-secret fields only. `--json` is a reporting mode, so it must not
        # also fall through and print the token itself. `--write-env` still
        # applies, which is what makes `--json --write-env` useful.
        if resp is None:
            resp = json.loads(CACHE.read_text())
        print(json.dumps({k: v for k, v in resp.items() if k != "token"}, indent=2))

    if "--write-env" in args:
        ENVFILE.write_text(f"export GH_TOKEN={token}\n")
        ENVFILE.chmod(0o600)
        print(f"wrote {ENVFILE}")
    elif "--export" in args:
        print(f"export GH_TOKEN={token}")
    elif "--json" not in args:
        print(token)


if __name__ == "__main__":
    main()
