# Configuration names

The flake exposes one NixOS configuration per machine. The set of names is part of the maintainer contract: adding or renaming a machine shows up here before anyone deploys it.

## Sub-features

- Evaluate `builtins.attrNames` of `nixosConfigurations` as JSON.
- Compare the sorted names to asymmetry, grokbox, installer, parallax, and stylix-test.
- Record isolation. Evaluation must not build a toplevel or create `./result`.

## How to get to it (user POV)

The maintainer asks Nix which configurations exist, without building them: `nix eval .#nixosConfigurations --apply builtins.attrNames --json`. The names match the directories under `machines/`. `attrNames` does not force each `nixosSystem` value, so this is the cheap listing; the base-import check is what forces the modules.

## Driving it with verify-flake

```bash
.cursor/skills/verify-flake/bin/verify-flake launch
.cursor/skills/verify-flake/bin/verify-flake doctor
.cursor/skills/verify-flake/bin/verify-flake drive nixos-configuration-names
```

The drive runs `machine-names` and `names-isolation`. `names.txt` lists the evaluated names. A mismatch writes `failure.txt` and fails the drive. Mode must be `nix-develop`.

## Gotchas

- Order in the JSON does not matter. The comparison sorts both sides.
- A new machine directory that is wired into `nixosConfigurations` fails this drive until `MACHINE_NAMES` in `bin/verify-flake` and this file are updated together.
- Degraded mode writes `unmet.txt` and exits 2. That is not a pass.
