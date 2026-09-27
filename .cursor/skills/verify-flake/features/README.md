# Flake features

The surface is the maintainer CLI: `just` and Nix builds that do not activate a machine. Quickshell is `verify-quickshell`.

| Feature | What it proves | Drive |
| --- | --- | --- |
| `just-recipe-list` | Bare `just`, `just --list`, and `just --summary` agree, and every public recipe is named | `verify-flake drive just-recipe-list` |
| `flake-check-base-import` | `checks.x86_64-linux.nixos-configurations-import-base` builds | `verify-flake drive flake-check-base-import` |
| `nix-build-toplevel-dry` | The installer toplevel builds with `--no-link` and `/run/current-system` stays put | `verify-flake drive nix-build-toplevel-dry` |
| `nixos-configuration-names` | `nixosConfigurations` names are asymmetry, grokbox, installer, parallax, stylix-test | `verify-flake drive nixos-configuration-names` |

Prove `just-recipe-list` after a Justfile change. The Nix rows need `mode=nix-develop` and are heavier; drive one of them when the change is in `modules/checks.nix`, a machine, or the installer closure.
