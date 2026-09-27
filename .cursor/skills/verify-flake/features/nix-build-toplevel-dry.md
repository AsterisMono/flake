# Installer toplevel, dry

`nixosConfigurations.installer` is the configuration that can be built without the workstation secret consumers. Building its toplevel with `--no-link` checks that the closure evaluates and realizes, and leaves the running system alone.

## Sub-features

- Record `/run/current-system` before the build.
- Build `nixosConfigurations.installer.config.system.build.toplevel` with `--no-link`.
- Require the store path to exist, to contain `installer`, and to leave `/run/current-system` unchanged.

## How to get to it (user POV)

The maintainer builds a toplevel when they want the system closure without installing it. From the repository root that is `nix build .#nixosConfigurations.installer.config.system.build.toplevel`. Adding `--no-link` keeps Nix from creating `./result`, so the worktree stays clean. Booting that closure is a different, explicit operation (`just boot` / `just install`) and is not part of this feature.

## Driving it with verify-flake

```bash
.cursor/skills/verify-flake/bin/verify-flake launch
.cursor/skills/verify-flake/bin/verify-flake doctor
.cursor/skills/verify-flake/bin/verify-flake drive nix-build-toplevel-dry
```

The drive runs `toplevel-installer` and `toplevel-isolation`. `current-system-before.txt` and `current-system-after.txt` must match. `command.txt` records:

```text
nix build .#nixosConfigurations.installer.config.system.build.toplevel --no-link --print-out-paths -L
```

## Gotchas

- This is a large build. It is not the default proof. Drive `just-recipe-list` unless the change is in the installer closure.
- `just build` is not this feature. `just build` calls `nh os build` for the current host.
- Workstation machines (`asymmetry`, `parallax`) pull secret-consuming aspects. This drive stays on `installer` so it does not need decrypted secrets. The toplevel still must not be switched.
