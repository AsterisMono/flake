# Flake verification map

This directory is the maintained source for verifying the user-facing CLI of this Nix flake. Read the index before driving, then use the matching feature file as the recipe.

## Baseline preconditions

- The working directory is the flake checkout (the directory that contains `flake.nix` and `Justfile`).
- `nix` is on `PATH` with flakes available. The harness passes `--extra-experimental-features 'nix-command flakes'` itself.
- Launch with `.cursor/skills/verify-flake/bin/verify-flake launch` and require `doctor` to print `doctor=ok`.
- Drives share that launch. Do not point a drive at a `result` symlink the user already had in the checkout.
- A foreign host (no `/run/current-system`, or `/etc/os-release` not `ID=nixos`) is valid for every feature in this map. It is not a managed NixOS host, so nothing in this map may switch, boot, or install.

## Driving conventions

- Start from the launch snapshot unless a feature says otherwise.
- Treat every command as literal. Keep machine names and flake attribute paths unchanged.
- Run actions through `.cursor/skills/verify-flake/bin/verify-flake drive …`.
- The harness uses one tmux session, `verify-flake-<run-id>`, and kills that session by name.
- Do not remove proof artifacts during cleanup.

## Proof and skip reporting

- Capture the command, stdout, stderr, and exit code.
- Capture the system profile link before and after. A build that changes `/run/current-system` is a failed verification even if the build exited 0.
- Capture whether `./result` appeared. Builds in this map pass `--no-link`.
- Record the feature id and the machine name when a drive takes one.
- Report an unreachable path with the attempted command and the unmet precondition, including a missing `nix` binary or an evaluation error.
- Do not report a skipped feature as verified through a different feature.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior. It then uses exactly four H2 sections in this order.

1. `Sub-features` lists short IDs with one line for each behavior.
2. `How to get to it (user POV)` lists every user entry point.
3. `Driving it with verify-flake` starts with `Preconditions:` and uses labeled bullets that pair each user action with an exact command and observable result.
4. `Gotchas` lists traps that can waste or invalidate a verification run.

Keep implementation essays out of the map. Name user paths, commands, required state, and observable proof.

## Features

- [List operations](./list-operations.md) covers `just` listing recipes without running them.
- [Import base](./import-base.md) covers the check that every NixOS configuration imports the base role.
- [Build a toplevel](./toplevel-build.md) covers building one machine's system closure without activating it.
- [Build the installer ISO](./installer-iso.md) covers building the installer image without booting or installing a disk.
