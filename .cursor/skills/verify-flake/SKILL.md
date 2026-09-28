---
name: verify-flake
description: "Drive this Nix flake's safe CLI path — nix develop, just --list, the import-base check, and build-without-activate — and refuse deploy, install, boot, dry-run, garbage collection, and secret operations. Use when proving flake operations or checks on a checkout, including a foreign CI VM that must not switch a system."
---

# Verify the flake

The surface is the repository CLI, not a graphical app. A user clones the checkout, enters `nix develop`, and runs `just` (which only lists recipes) or a build that does not activate. Machines live under `modules/machines/` and are materialized as `nixosConfigurations.<name>`. The names today are `asymmetry`, `grokbox`, `installer`, `parallax`, and `stylix-test`, all `x86_64-linux`.

This skill does not replace `.agents/skills/init-machine` or `.agents/skills/install-machine`. Those enroll and install hosts. Verification stops at evaluation and `nix build`.

`just deploy`, `just boot`, `just dryrun`, `just install`, `just rdeploy`, `just gc`, `just updatekeys`, `just rewrap-secret`, `just generate-luks-password`, `just prompt-luks-password`, `just collect-machine-info`, and `just elevate` are outside this skill. AGENTS.md requires explicit authorization for them. The harness exits if a drive id matches one of those recipe names.

On a machine that is not NixOS, or whose `/run/current-system` is not the machine under test, do not run `nh os build`, `nh os switch`, or `nixos-rebuild`. Cursor cloud VMs are Ubuntu (or similar) and have no system profile to switch. Build with `nix build --no-link` and prove the profile link did not appear or change.

## Launch

From the repository root:

```sh
.cursor/skills/verify-flake/bin/verify-flake launch
```

Launch is ready when it prints the run directory and `evidence/launch/develop.out` exists. Internally it:

1. Requires `nix` on `PATH` and `tmux` later, for drives. It does not install Nix.
2. Records `/run/current-system` (`absent` on this kind of VM) and snapshots `.git/hooks`.
3. Runs `nix flake metadata --json`.
4. Runs `nix develop --command true` once, so later drives reuse the shell. The development shell's pre-commit hook may rewrite `.git/hooks`; cleanup puts the snapshot back.

There is no long-running server. Each drive then starts in its own tmux session named `verify-flake-<run-id>`.

If `nix` is missing, launch exits with that fact. Do not fall back to `just deploy` or a system activation.

## Doctor

```sh
.cursor/skills/verify-flake/bin/verify-flake doctor
```

Doctor is read-only. It passes only when all of these hold:

- Launch finished (`ready` exists).
- `nix` is still on `PATH`.
- `flake.nix`, `Justfile`, and `modules/checks.nix` exist.
- `/run/current-system` is unchanged since launch.
- The checkout has no `result` or `result-1` symlink.

It records `host_class=nixos` only when `/etc/os-release` says `ID=nixos` and `/run/current-system` exists. Otherwise `host_class=foreign`. Foreign is still worth driving for list, check, and `nix build`. It is not worth `nh os switch`.

## Drive

The harness is `verify-flake`. Run one mapped feature:

```sh
.cursor/skills/verify-flake/bin/verify-flake drive list-operations
.cursor/skills/verify-flake/bin/verify-flake drive import-base
.cursor/skills/verify-flake/bin/verify-flake drive toplevel --machine stylix-test
.cursor/skills/verify-flake/bin/verify-flake drive installer-iso
```

`list-operations` runs `nix develop --command just --list` inside tmux. That is the README path (`just` with no arguments lists recipes; the harness calls `just --list` so the output is the list itself and not a second copy of the default recipe). Stdout must name `build`, `deploy`, and `build-installer-iso`. Naming `deploy` in the list is not running it.

`import-base` runs:

```sh
nix build --no-link --print-out-paths .#checks.<system>.nixos-configurations-import-base
```

`<system>` is `builtins.currentSystem` (this fleet is `x86_64-linux`). The check is the assert in `modules/checks.nix`: every `nixosConfigurations` entry must import the `base` role. Success is exit 0 and a store path whose file exists. A failure names the configurations that skipped `base`.

`toplevel` builds `.#nixosConfigurations.<machine>.config.system.build.toplevel` with `--no-link`. The machine must match `modules/machines/<machine>.nix`. The output must be a directory that looks like a NixOS system (`etc` or `sw/bin/sh`). This does not call `switch-to-configuration`.

`installer-iso` builds `.#nixosConfigurations.installer.config.system.build.isoImage` with `--no-link` and requires a `.iso` in the output directory. It does not boot or write a disk.

Every drive records the system profile before and after and fails if they differ, and fails if `./result` appeared.

Recipes and flags are literal. Do not insert `--sudo`, `switch`, or `nh os`.

## Evidence

Proof for a drive is the directory printed by the harness, under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/verify-flake/runs/<run-id>/evidence/<feature>/
```

Each drive writes `command.txt`, `stdout.txt`, `stderr.txt`, `exit-code.txt`, `profile-before.txt`, `profile-after.txt`, `result-link.txt`, and `git-status-after.txt`. Launch evidence (nix version, flake metadata, develop log, profile before launch) stays in `evidence/launch/`.

A passing drive shows exit code `0`, identical profile snapshots, and `result-link.txt` containing `absent`. `import-base` and the build drives also record `out-path.txt`. That out path is in the Nix store; quote it in the report. Do not treat a store path as a switched generation.

`nix build` and `nix develop` download from the network and write the store. That is the production build path, not a hidden activation. Confirm activation did not happen by the unchanged profile link, not by the command's name.

List the feature id in the report. A skipped feature is not verified by a different one.

```sh
.cursor/skills/verify-flake/bin/verify-flake evidence
```

## Cleanup

```sh
.cursor/skills/verify-flake/bin/verify-flake cleanup
```

Cleanup kills the tmux session named in the run's `meta.env` and no other session. It restores `.git/hooks` from the launch snapshot and deletes only the run's `scratch/` directory. It leaves `evidence/` in place. Confirm the evidence directory still exists after cleanup before calling the run done.

## Helpers

The only helper is `.cursor/skills/verify-flake/bin/verify-flake`. It is executable. Invoke it by that path from the repository root, as the sections above do. `verify-flake` with no arguments prints usage and exits 2.
