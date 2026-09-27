---
name: verify-flake
description: Verify this NixOS flake the way the maintainer does, using just recipe listings, the base-import check, a dry installer toplevel build, and configuration names. Never deploy, switch, boot, collect hardware, or rewrite secrets. Quickshell is a separate skill.
---

# Verify the flake

This skill drives the maintainer CLI for the flake: `just` and Nix evaluation or builds that do not activate a system. `modules/apps/quickshell` is a separate surface; use `verify-quickshell` to run the shell. Do not `just deploy`, `boot`, `dryrun`, `install`, `rdeploy`, `gc`, `updatekeys`, `rewrap-secret`, `generate-luks-password`, `prompt-luks-password`, `collect-machine-info`, `elevate`, or `build-installer-iso`.

`nix develop` installs the repo git hooks as a side effect. Launch snapshots them and cleanup restores that snapshot, including removing `.pre-commit-config.yaml` when it was absent at launch.

Run the helper from any working directory. Paths below are relative to the flake root. After a change to `Justfile`, `modules/checks.nix`, or `machines/`, re-prove one mapped feature with `/maintain-verification-skill`.

## Launch

```bash
.cursor/skills/verify-flake/bin/verify-flake launch
```

Launch runs `nix develop --command just --version` when Nix is available. Mode is `nix-develop` when that exits 0. Mode is `degraded` when Nix or the develop shell fails but `just` is still on `PATH`. Mode is `blocked` when neither works; launch then exits 1.

A second launch without cleanup fails.

Ready line:

```text
verify-flake: ready run=<UTC>-<pid> mode=<mode>
```

## Doctor

```bash
.cursor/skills/verify-flake/bin/verify-flake doctor
```

Doctor is read-only. Exit 0 for `ok` or `degraded`, exit 1 for `fail`. It prints Nix and just versions, the system, `HEAD`, whether the public Justfile recipes are present, and whether a mutating `just` or `nixos-rebuild` process is running. It does not run those recipes.

`worth-driving` lists `just-recipe-list` whenever `just` can run. It lists `flake-check-base-import`, `nix-build-toplevel-dry`, and `nixos-configuration-names` only when mode is `nix-develop`.

The quickshell module is reported as a separate surface.

## Drive

The cheap proof is the recipe list:

```bash
.cursor/skills/verify-flake/bin/verify-flake drive just-recipe-list
```

That runs bare `just`, `just --list`, and `just --summary` inside `nix develop` when launch reached that mode. Bare `just` must match `just --list`, and both must name every public recipe. The summary must contain the same names as whole tokens. The drive does not run any of those recipes.

Nix features, only in `nix-develop` mode:

```bash
.cursor/skills/verify-flake/bin/verify-flake drive flake-check-base-import
.cursor/skills/verify-flake/bin/verify-flake drive nix-build-toplevel-dry
.cursor/skills/verify-flake/bin/verify-flake drive nixos-configuration-names
```

`flake-check-base-import` builds `.#checks.x86_64-linux.nixos-configurations-import-base` with `--no-link`. `nix-build-toplevel-dry` builds `.#nixosConfigurations.installer.config.system.build.toplevel` with `--no-link` and does not switch to it. `nixos-configuration-names` evaluates `builtins.attrNames` of `nixosConfigurations` and expects `asymmetry`, `grokbox`, `installer`, `parallax`, and `stylix-test`.

Refused feature names exit 1 and do not write a passing evidence directory: `deploy`, `boot`, `dryrun`, `install`, `rdeploy`, `gc`, `updatekeys`, `rewrap-secret`, `generate-luks-password`, `prompt-luks-password`, `collect-machine-info`, `elevate`, `build-installer-iso`.

Passing line:

```text
verify-flake: drove <feature-id> run=<run-id> evidence=<evidence-dir>
```

Outside `nix-develop`, a Nix feature writes `unmet.txt` and exits 2. That drive did not pass.

## Evidence

Each drive writes `.cursor/skills/verify-flake/evidence/<run-id>/<feature-id>/` with `meta.txt`, `feature-id.txt`, `entry-point.txt`, `command.txt`, stdout, stderr, exit codes, and `isolation.txt`. Isolation must show `result-symlink: absent`, `git-status: unchanged`, and `mutating-processes: none`. A toplevel drive also records `/run/current-system` before and after. Cleanup does not delete this tree.

## Cleanup

```bash
.cursor/skills/verify-flake/bin/verify-flake cleanup
```

Cleanup restores the git hooks snapshot from launch and deletes the scratch directory. Evidence remains.

```text
verify-flake: cleaned run=<run-id> evidence=<evidence-dir>
```

## Helpers

| Command | What it does |
| --- | --- |
| `.cursor/skills/verify-flake/bin/verify-flake launch` | Enter `nix develop` or record a degraded just-only mode |
| `.cursor/skills/verify-flake/bin/verify-flake doctor` | Report mode, versions, and which features are worth driving |
| `.cursor/skills/verify-flake/bin/verify-flake drive <feature-id>` | Run every step of one mapped feature |
| `.cursor/skills/verify-flake/bin/verify-flake step <step-id>` | Run one step; `steps` lists them |
| `.cursor/skills/verify-flake/bin/verify-flake cleanup` | Restore hooks and delete scratch |

`just build` is `nh os build` for the current host. It is not a verification command here. The dry toplevel, when driven, is the `installer` configuration via `nix build --no-link`.

Feature map: `features/README.md`. Quickshell: `.cursor/skills/verify-quickshell/SKILL.md`.
