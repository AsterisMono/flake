# Base-import check

Every machine configuration has to import `base`. `modules/checks.nix` turns that into the flake check `nixos-configurations-import-base`.

## Sub-features

- Build `checks.x86_64-linux.nixos-configurations-import-base` with `--no-link`.
- Require the printed store path to exist and to end in `nixos-configurations-import-base`.
- Record isolation. The check must not leave a `result` symlink or change `/run/current-system`.

## How to get to it (user POV)

The maintainer runs `nix flake check`, or builds this one check when the full check set is more than the question needs. A failing check means some `machines.<name>` configuration evaluated without importing `base`. A passing check is an empty derivation output; it does not switch the running system.

## Driving it with verify-flake

```bash
.cursor/skills/verify-flake/bin/verify-flake launch
.cursor/skills/verify-flake/bin/verify-flake doctor
.cursor/skills/verify-flake/bin/verify-flake drive flake-check-base-import
```

The drive runs `check-base-import` and `check-isolation`. The command recorded in `command.txt` is:

```text
nix build .#checks.x86_64-linux.nixos-configurations-import-base --no-link --print-out-paths -L
```

`store-path.txt` is the last line of stdout. Mode must be `nix-develop`. Any other mode writes `unmet.txt` and exits 2.

## Gotchas

- The check forces every configuration's module options. It is heavier than `just-recipe-list`. Skip it when doctor is degraded.
- `currentSystem` other than `x86_64-linux` is unmet. This flake's machines are `x86_64-linux`; the drive will not cross-build the check.
- A successful build still does not activate a generation. There is no `switch` step to add.
