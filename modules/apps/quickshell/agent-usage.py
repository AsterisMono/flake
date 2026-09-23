"""Read account usage for the Quickshell work panel."""

import json
import os
import selectors
import subprocess
import sys
import time
import urllib.error
import urllib.request
from decimal import Decimal, InvalidOperation


def codex(executable):
    requests = [
        {
            "method": "initialize",
            "id": 0,
            "params": {
                "clientInfo": {
                    "name": "quickshell_agent_panel",
                    "title": "Quickshell Agent Panel",
                    "version": "1.0.0",
                }
            },
        },
        {"method": "initialized", "params": {}},
        {"method": "account/rateLimits/read", "id": 1},
    ]
    process = subprocess.Popen(
        [executable, "app-server", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    try:
        process.stdin.write("".join(json.dumps(request) + "\n" for request in requests).encode())
        process.stdin.flush()
        with selectors.DefaultSelector() as selector:
            selector.register(process.stdout, selectors.EVENT_READ)
            pending = b""
            deadline = time.monotonic() + 12
            while time.monotonic() < deadline:
                if not selector.select(deadline - time.monotonic()):
                    break
                chunk = os.read(process.stdout.fileno(), 65536)
                if not chunk:
                    break
                pending += chunk
                while b"\n" in pending:
                    line, pending = pending.split(b"\n", 1)
                    message = json.loads(line)
                    if message.get("id") == 1:
                        return codex_result(message.get("result") or {})
    finally:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    return {"ok": False}


def codex_result(result):
    buckets = result.get("rateLimitsByLimitId") or {}
    if not buckets and result.get("rateLimits"):
        bucket = result["rateLimits"]
        buckets = {bucket.get("limitId", "codex"): bucket}
    windows = []
    for bucket in buckets.values():
        for window in (bucket.get("primary"), bucket.get("secondary")):
            if not window or window.get("usedPercent") is None:
                continue
            windows.append(
                {
                    "limit": bucket.get("limitName") or bucket.get("limitId") or "Codex",
                    "minutes": window.get("windowDurationMins"),
                    "remaining": max(0, min(100, 100 - float(window["usedPercent"]))),
                    "resetsAt": window.get("resetsAt"),
                }
            )
    return {"ok": bool(windows), "windows": windows}


def deepseek(key_path):
    with open(key_path, encoding="utf-8") as key_file:
        key = key_file.read().strip()
    request = urllib.request.Request(
        "https://api.deepseek.com/user/balance",
        headers={"Authorization": "Bearer " + key},
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        data = json.load(response)
    balances = [
        {"currency": item["currency"], "total": item["total_balance"]}
        for item in data.get("balance_infos", [])
        if item.get("currency") and item.get("total_balance") is not None
    ]
    return {"ok": bool(balances), "balances": balances, "available": data.get("is_available")}


def openrouter(key_path):
    with open(key_path, encoding="utf-8") as key_file:
        key = key_file.read().strip()
    if not key:
        return {"ok": False}
    request = urllib.request.Request(
        "https://openrouter.ai/api/v1/credits",
        headers={"Authorization": "Bearer " + key},
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        data = json.load(response)
    credits = data["data"]
    remaining = Decimal(str(credits["total_credits"])) - Decimal(str(credits["total_usage"]))
    return {"ok": True, "balance": f"{remaining:.2f}", "currency": "USD"}


def main():
    try:
        if sys.argv[1] == "codex":
            output = codex(sys.argv[2])
        elif sys.argv[1] == "deepseek":
            output = deepseek(sys.argv[2])
        elif sys.argv[1] == "openrouter":
            output = openrouter(sys.argv[2])
        else:
            output = {"ok": False}
    except (OSError, ValueError, InvalidOperation, KeyError, IndexError, subprocess.TimeoutExpired, urllib.error.URLError):
        output = {"ok": False}
    print(json.dumps(output, separators=(",", ":")))


if __name__ == "__main__":
    main()
