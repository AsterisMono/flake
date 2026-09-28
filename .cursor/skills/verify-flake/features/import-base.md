# Import base

Import base fails the flake check when any NixOS configuration was materialized without importing the base role.

## Sub-features

- `check-passes` builds `checks.<system>.nixos-configurations-import-base` and gets a store path.
- `check-names-offenders` when the assert fails, the error lists configuration names that skipped base.

## How to get to it (user POV)

- Run `nix flake check` on the checkout. This check is one of the flake checks.
- Build the single check when the rest of `nix flake check` (package builds and the pre-commit hook derivation) is more than the question being asked:

```sh
nix build .#checks.x86_64-linux.nixos-configurations-import-base
```

Replace `x86_64-linux` with `builtins.currentSystem` when the builder is not that system. Every machine in this repo is `x86_64-linux`.

## Driving it with verify-flake

Preconditions:

- `verify-flake doctor` prints `doctor=ok`.
- The builder can evaluate `nixosConfigurations`. The check forces that evaluation because `modules/checks.nix` reads every configuration's options.

- **Run the check.** Run `.cursor/skills/verify-flake/bin/verify-flake drive import-base`. Exit code `0`. `out-path.txt` is a file in the Nix store.
- **No activation.** `profile-before.txt` and `profile-after.txt` match. `result-link.txt` is `absent`. The harness passes `--no-link`, so the user's checkout gains no `result` symlink.

## Gotchas

- A successful check is an empty file produced by `pkgs.runCommand` after the assert. The proof is the exit code plus that path, not the file's contents.
- Evaluation instantiates every machine, including disko, lanzaboote, and Home Manager. It does not switch them. It still needs the flake inputs and a lot of memory.
- `nix flake check` also builds `packages` and `checks.<system>.pre-commit-check`. Those are not this feature. Do not describe a package build as the import-base result.
- On failure, quote the assert message. Do not "fix" a machine by weakening the check.
