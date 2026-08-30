---
name: anywhere
description: Install a repository machine with nixos-anywhere, including SSH access, host age recipient enrollment, sops recipient refresh, and prerequisite commits. Use only when explicitly invoked with /skill:anywhere.
disable-model-invocation: true
---

# NixOS Anywhere installation

Install one of this repository's machine configurations on a remote target. This workflow is destructive to the target machine. Follow the steps in order and stop on any ambiguity or failed check.

An explicit `/skill:anywhere` invocation authorizes `just scan-age-key`, `just updatekeys`, and `just install` for the confirmed target. It does not authorize unrelated deployment, key rotation, or cleanup commands.

## 1. Collect and confirm the target

Accept the machine IP address and repository hostname from the command arguments when supplied. Ask only for missing values.

- Treat the hostname as the name exported through `flake.nixosConfigurations`.
- Default the SSH target to `root@<machine-ip>` unless the user supplied another SSH user.
- Confirm that the hostname exists in the flake before making remote or secret-recipient changes.
- Repeat the hostname, IP address, and effective SSH target to the user. Resolve any mismatch before continuing.

Never guess a hostname or target address.

## 2. Establish SSH access

First try non-interactive key authentication, accepting a new host fingerprint but not replacing a conflicting known-host entry:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "$target" true
```

Distinguish authentication failure from routing, timeout, DNS, and host-key errors. Do not request a password for a non-authentication failure.

If password authentication is required:

1. Ask the user for the target's temporary password.
2. Keep it only in the `SSHPASS` environment variable. Never echo it, interpolate it into diagnostic output, write it to a file, or commit it.
3. Use `sshpass -e` to authenticate and install the maintainer's SSH public key with `ssh-copy-id`, so the repository's ordinary `ssh`-based Just recipes work without prompts.
4. Unset `SSHPASS` as soon as key-based access succeeds.

If `sshpass`, `ssh-copy-id`, or a suitable local public key is unavailable, stop and tell the user what is missing rather than weakening SSH settings or persisting the password. Re-run the non-interactive SSH test and continue only after it succeeds.

## 3. Enroll the target age recipient

Capture the public age recipient from the target without printing unrelated SSH output:

```bash
just scan-age-key "$target"
```

Validate that the result is exactly one plausible `age1...` recipient. Then edit `.sops.yaml`:

- Add or update a key anchor named for the desired hostname.
- Include that anchor in the generic `modules/secrets/[^/]+\.(yaml|json|env|ini)$` creation rule.
- Preserve narrower creation rules and all existing recipients unless the user explicitly requests otherwise.
- If the hostname already exists with a different recipient, stop and ask before replacing it.

Run the explicitly authorized recipient refresh:

```bash
just updatekeys
```

Inspect the resulting diff. Stop if plaintext secrets appear, files outside the expected encrypted secret set change, or `sops` reports an error.

## 4. Make prerequisite commits

Before committing, inspect all staged and unstaged changes with `git status` and the relevant diffs.

- Preserve unrelated work and never silently combine unrelated changes.
- If pre-existing changes are already staged, review and commit them separately before the age-recipient changes when they form a coherent commit. Ask for guidance if their intent or commit boundary is unclear.
- Do not stage unrelated unstaged changes merely to obtain a clean tree.
- Stage `.sops.yaml` and the encrypted documents changed by `just updatekeys`, then commit them as one focused recipient-enrollment commit.
- Follow repository history: use concise, lowercase, imperative subjects such as `<hostname>: add age recipient`.
- Do not create an empty commit.

Before installation, verify that every file required by the selected flake configuration is tracked and that no required recipient-enrollment change remains uncommitted. Report any unrelated dirty files, but do not commit them without the user's informed approval.

## 5. Install

Immediately before the destructive operation, show the resolved hostname and SSH target and obtain explicit confirmation that this is the machine to erase and install. Then run exactly:

```bash
just install "$hostname" "$target"
```

Stream and report the result. Do not retry a partially completed installation blindly. On failure, preserve the output, identify the failed phase, and ask before taking any additional machine-mutating action.
