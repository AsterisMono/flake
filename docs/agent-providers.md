# Agent providers

Import `inputs.self.modules.aspects.agent-providers` alongside `base` to install
Codex, Pi, and the backup Cursor Agent, together with their runtime tools. The
full workstation `agents` aspect already includes it. Use Codex for OpenAI's
account login and Pi for DeepSeek and OpenRouter models. OpenCode is no longer
installed or provisioned.

The machine must be an authorized recipient of `agent-providers.yaml`. Existing
readers are Asymmetry and Parallax; the maintainer can edit the whole document.
Adding a reader requires enrolling its host recipient and an explicitly
authorized ciphertext rewrite, following [secret guidance](../AGENTS.md).

## Activation and authentication

NixOS activation decrypts these four values to runtime files with mode `0400`:

| Encrypted document key | Use |
| --- | --- |
| `deepseek_api_key` | Pi's DeepSeek API authentication |
| `openrouter_api_key` | Pi's OpenRouter API authentication |
| `codex_auth_json` | JSON string containing the Codex account login cache |
| `cursor_auth_json` | JSON string containing the Linux Cursor Agent login cache |

The Noctalia balance consumer separately provisions `openrouter_management_key`
from the same document. Its initial encrypted value is
`REPLACE_WITH_OPENROUTER_MANAGEMENT_KEY`; replace that placeholder with `sops`
to enable account balance queries. It is not passed to Pi or the Paseo service.

`agent-provider-auth.service` runs after `sops-install-secrets.service` and
initializes the personal account's home, or root's home on a headless machine
without that account. It creates private directories (`0700`) and initializes:

- `~/.codex/auth.json`: writable Codex credentials (`0600`), allowing token refresh.
- `$XDG_CONFIG_HOME/cursor/auth.json` (normally `~/.config/cursor/auth.json`):
  writable Cursor credentials (`0600`), using the locked Linux CLI's file storage.
- `~/.pi/agent/auth.json`: writable Pi credentials (`0600`), containing the
  DeepSeek and OpenRouter API-key entries.

The Python initializer reads the decrypted runtime files and renders Pi's JSON
with the two API keys. Writes are atomic, with private directories and files;
credentials never enter Nix evaluation or the store. Existing Pi credentials
for other providers are retained. Any earlier template symlink is replaced with
a regular authentication file.

Pi reads these API-key entries without `/login`. Change the managed DeepSeek and
OpenRouter keys with `sops`; activation updates their entries. Start a new Pi
process after changing a key. See
[Pi authentication](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/providers.md).

Codex and Cursor adopt existing local logins on first activation. A fingerprint
beside each login cache records the encrypted seed that has been applied. Later
activation and reboot preserve locally refreshed credentials. A changed seed,
or a missing login cache, installs the encrypted snapshot again. The encrypted
document is a bootstrap snapshot; runtime token refresh does not update it.
If the account session expires or is revoked, reauthenticate and replace the
encrypted snapshot with `sops`. Never link a mutable login cache directly to a
read-only secret or a Nix store file. OpenAI documents copying the account cache
to headless machines in [Codex authentication](https://developers.openai.com/codex/auth).

The same Python initializer writes all three tools' authentication files.
Existing settings, sessions, skills, and model choices remain in each tool's
normal home. Pi's managed DeepSeek and OpenRouter entries take precedence over
provider environment variables.

The usage bar reports DeepSeek and OpenRouter balances. OpenRouter's `/credits`
endpoint requires the separate management key; its placeholder is skipped by
the wrapper until configured. The regular OpenRouter key remains available to Pi.
See [OpenRouter credits](https://openrouter.ai/docs/api/api-reference/credits/get-remaining-credits).

## Paseo

Paseo Desktop launches tools as the desktop user, so it uses these normal login
and Pi authentication files. No shell login or global secret environment is
required.

The standalone [Paseo daemon](paseo-daemon.md) runs as `paseo`, with a separate
home. Systemd passes the four runtime secrets through `LoadCredential`. Its
`ExecStartPre` initializes writable Codex/Cursor caches and renders Pi's
authentication file under `/var/lib/paseo`. A changed secret restarts this
service so its credential snapshot is refreshed. The service cannot read the
desktop home.

Paseo v0.10.2 exposes Codex and Pi. Its source contains a Cursor adapter but its
provider manifest does not register Cursor, so installing and authenticating
`cursor-agent` alone does not make it selectable in this Paseo version. It
remains usable directly as the backup CLI.

## Verification

After separately authorized deployment, run these commands as the account
whose tools you want to check (or as `paseo` with its service home):

```sh
codex login status
pi auth check --provider deepseek --json --no-refresh
pi auth check --provider openrouter --json --no-refresh
```

Pi's `auth check` confirms local credential resolution, not acceptance by the
provider API. Do not pass `--credentials` or use the credential-printing
commands in logs. Model availability can also be inspected through Paseo's Pi
provider, whose RPC discovery reads the same authentication configuration.
