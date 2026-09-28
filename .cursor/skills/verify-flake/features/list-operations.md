# List operations

List operations shows the repository's Just recipes and does not build, switch, or read a secret.

## Sub-features

- `list-recipes` prints every recipe group from the checkout's Justfile.
- `list-does-not-activate` leaves the system profile untouched while the list is printed.

## How to get to it (user POV)

- From the checkout, enter `nix develop`, then run `just` with no arguments. The default recipe lists recipes.
- Run `just --list` for the same list without going through the default recipe.

## Driving it with verify-flake

Preconditions:

- `verify-flake launch` has finished and `verify-flake doctor` prints `doctor=ok`.
- `nix develop` can realize the shell that contains `just`.

- **List recipes.** Run `.cursor/skills/verify-flake/bin/verify-flake drive list-operations`. Exit code `0`. `evidence/list-operations/stdout.txt` contains recipe names `build`, `deploy`, and `build-installer-iso`. `evidence/list-operations/command.txt` is `nix develop` of this checkout with `--command just --list`.
- **Activation stayed off.** Compare `profile-before.txt` and `profile-after.txt` in that evidence directory. They are identical. `result-link.txt` is `absent`. Stderr does not contain `switching profile`.

## Gotchas

- Bare `just` lists recipes. It does not deploy. Seeing `deploy` in the list is the point of the list, not permission to run it.
- `nix develop` runs the pre-commit shellHook and may rewrite `.git/hooks`. Cleanup restores the launch snapshot. Do not commit hook changes from a verification run.
- `just build` is `nh os build .` and is a host operation. It is not this feature. Use `toplevel-build` for a build that does not depend on the current host matching a machine.
- A foreign VM has no NixOS profile. `profile-*.txt` then both read `absent`, which is the passing observation.
