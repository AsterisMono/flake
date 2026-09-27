# Just recipe list

The default Justfile recipe prints the public recipe list. That list is the maintainer's map of what the flake can do, including the recipes this skill must not run.

## Sub-features

- Run bare `just` and require the recipe list on stdout.
- Run `just --list` and require the same stdout.
- Run `just --summary` and require each public recipe as a whole token.
- Record isolation: no `result` symlink, no mutating process, git status unchanged.

## How to get to it (user POV)

From a checkout, the maintainer enters the development shell and runs `just` with no arguments. Just prints `Available recipes:` and the public names. `just --list` is the same view. `just --summary` is the space-separated form used by scripts. Private recipes stay hidden. Nothing in this view builds a system or rewrites a key.

## Driving it with verify-flake

```bash
.cursor/skills/verify-flake/bin/verify-flake launch
.cursor/skills/verify-flake/bin/verify-flake doctor
.cursor/skills/verify-flake/bin/verify-flake drive just-recipe-list
```

The drive runs `just-default`, `just-list`, `just-summary`, and `just-isolation`. In `nix-develop` mode each just invocation is `nix develop --command just ...`. Evidence stdout files must list `build`, `dryrun`, `deploy`, `boot`, `rdeploy`, `elevate`, `install`, `collect-machine-info`, `build-installer-iso`, `generate-luks-password`, `prompt-luks-password`, `updatekeys`, `rewrap-secret`, and `gc`. `default-stdout.txt` and `list-stdout.txt` must be identical. `list-diff.txt` records that match.

## Gotchas

- stderr is not required to be empty. Entering `nix develop` can print git-hook install noise; the assertion is on stdout and the exit code.
- `just build` appears in the list and must not be executed. It is `nh os build` for the current host.
- Degraded mode uses a `just` already on `PATH` and still refuses the mutating recipes. It does not unlock the Nix features.
