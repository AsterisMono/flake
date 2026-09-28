# Build a toplevel

Build a toplevel produces one machine's NixOS system closure and does not activate it.

## Sub-features

- `build-named-machine` builds `nixosConfigurations.<machine>.config.system.build.toplevel` for a name that has `modules/machines/<machine>.nix`.
- `build-does-not-switch` leaves `/run/current-system` unchanged on a NixOS host and absent on a foreign host.

## How to get to it (user POV)

- From the checkout, after adapting a machine definition, run the README command with the configuration name substituted for `MACHINE`:

```sh
nix build .#nixosConfigurations.MACHINE.config.system.build.toplevel
```

- On an already managed host, `just build` (`nh os build .`) builds the local system. That command follows the host's current configuration and is not the way to build a named machine from a foreign VM. This map uses the explicit attribute path.

## Driving it with verify-flake

Preconditions:

- `verify-flake doctor` prints `doctor=ok`.
- The machine argument is the basename of a file in `modules/machines/` (`asymmetry`, `grokbox`, `installer`, `parallax`, or `stylix-test`).
- The host is allowed to spend the time and store space of a full system build. A cloud VM that cannot finish the build is a blocked drive, not a pass.

- **Build without activating.** Run `.cursor/skills/verify-flake/bin/verify-flake drive toplevel --machine stylix-test` (or another machine name). Exit code `0`. `out-path.txt` is a directory containing `etc` or `sw/bin/sh`. `machine.txt` is the name that was requested.
- **Profile unchanged.** `profile-before.txt` and `profile-after.txt` match. `result-link.txt` is `absent`.

## Gotchas

- `stylix-test` is a QEMU guest definition used as a Quickshell-without-herdr composition. Building its toplevel still evaluates the workstation-adjacent modules it imports. It does not start QEMU.
- `nh os build` and `nixos-rebuild switch` are not substitutes. On a foreign host they do not know which machine this checkout should become, and switch is an activation.
- `--no-link` keeps the closure in the store only. Quoting the out path is the proof. Creating `./result` and then deleting it is not required and the harness treats a new `./result` as a failure.
- Building `installer`'s toplevel is not the installer ISO. The ISO is `installer-iso`.
