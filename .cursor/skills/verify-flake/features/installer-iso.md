# Build the installer ISO

Build the installer ISO produces the boot image for a new machine and does not boot it or write a disk.

## Sub-features

- `iso-builds` produces a directory that contains a `.iso`.
- `iso-does-not-install` does not call `nixos-anywhere` and does not change the system profile.

## How to get to it (user POV)

- From the workstation checkout, run `just build-installer-iso`.
- The same build attribute is `nix build .#nixosConfigurations.installer.config.system.build.isoImage`.

The following install, after the ISO boots on the target, is `.agents/skills/install-machine`, not this feature.

## Driving it with verify-flake

Preconditions:

- `verify-flake doctor` prints `doctor=ok`.
- The builder can afford an installer image. This is a large build. A VM that runs out of disk or time records the nix error and does not claim the ISO exists.

- **Build the image.** Run `.cursor/skills/verify-flake/bin/verify-flake drive installer-iso`. Exit code `0`. `out-path.txt` names a directory that contains a file ending in `.iso`.
- **No install.** `profile-before.txt` and `profile-after.txt` match. `result-link.txt` is `absent`. The command text does not contain `nixos-anywhere` or `disko`.

## Gotchas

- The ISO trusts the maintainer SSH key baked into the installer configuration. Building it does not enroll a new host. Do not start `just install` from this evidence.
- `just build-installer-iso` and the `nix build` attribute are the same image. Driving the attribute is enough; do not also run the Just recipe in the same proof unless the question is the recipe text.
- A `.iso` path in the store is not a booted installer. There is no serial console to drive from this feature.
