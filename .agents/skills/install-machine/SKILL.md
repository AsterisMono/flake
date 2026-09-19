---
name: install-machine
description: Install a machine from this flake onto a target booted from this flake's installer ISO using nixos-anywhere. Use when provisioning new or wiped hardware from the installer image; not for ordinary deploys of a machine that is already running.
disable-model-invocation: true
---

# Install a machine from the installer ISO

This erases the target's disks. Confirm the machine name, IP address, disk device, and layout before running nixos-anywhere.

## Collect first

- Ask the user for the target's IP address and whether the target is a workstation or a server. Use `root` as the SSH user unless they say otherwise.
- Match the answer to a layout and confirm the name with `nix eval .#diskoConfigurations --apply builtins.attrNames`: workstations use `xfs-workstation` (ESP, 32G swap, LUKS root, xfs `/` with `pquota`); servers use the server layout (`ext4-server-efi`: ESP plus a plain ext4 root, no LUKS and no swap). Use whatever layout the user names when it differs.

## Environment facts

- The target boots this repository's installer ISO (`just build-installer-iso`). It provides `just`, `nixos-anywhere`, the 1Password CLI, `git`, and an SSH daemon with `PermitRootLogin = yes` and the maintainer's public key in root's `authorizedKeys`, so `ssh root@<ip>` works without a password.
- `nixos-anywhere` runs the phases `kexec,disko,install,reboot` by default, and kexec replaces the live environment. Anything written into `/run` on the ISO beforehand is gone by then. Pass secrets with `--disk-encryption-keys <remote-path> <local-source>`, which is uploaded after kexec and before disko, or skip kexec with `--phases disko,install,reboot`.
- With `--disko-mode disko`, disko formats `disko.devices.disk.main.device` from the machine's `hardware` block, so that path must already point at the target disk.
- The flake is evaluated on the workstation, so new machine and layout files must be staged with `git add` before Nix can see them.

## Workflow

1. Define the machine in `modules/machines/<machine>.nix`: import the roles and aspects it needs, set `diskoConfig` to the chosen layout, and set `hardware.disko.devices.disk.main.device` to the target disk's `/dev/disk/by-id/...` path (read it on the target with `ls -l /dev/disk/by-id/`). Stage the file and confirm it evaluates: `nix eval --raw .#nixosConfigurations.<machine>.config.system.build.toplevel.drvPath`.
2. If the layout has a LUKS root, make sure the passphrase exists before disko runs. On a first install, run `just generate-luks-password <machine>` from a machine with an authenticated `op`; it stores `NixOS <machine> LUKS root` in the `NixOS` vault and leaves the passphrase at `/run/luks-password`.
3. Boot the target from the installer ISO and bring up networking with `nmtui`. Then confirm access from the workstation with `ssh root@<ip> true`. If the key is refused, stop and report instead of improvising credentials.
4. If the machine consumes sops secrets, enroll its host age recipient before installing: `just scan-age-key root@<ip>`, add or update its anchor in `.sops.yaml`, run `just updatekeys` (this rewrites the encrypted documents and needs explicit authorization), and commit the result. `--copy-host-keys` carries the same host keys into the installation, so the enrolled recipient stays valid.
5. Install with the Justfile recipe: `just install <machine> root@<ip>` for a server layout, or `just install <machine> root@<ip> /run/luks-password` when the layout has a LUKS root, which uploads the passphrase that `generate-luks-password` left in `/run/luks-password` so disko can read it after kexec.
6. Verify after the reboot: the machine boots and `nixos-rebuild build --flake .` succeeds on the installed system. On `xfs-workstation` also check the LUKS passphrase prompt, `swapon --show` reporting the 32G partition, and `resume=/dev/disk/by-partlabel/disk-main-swap` in `/proc/cmdline`.
7. Machines that import the `secure-boot` aspect (currently asymmetry) also need `sbctl` keys in `/var/lib/sbctl`. Create and enroll them (`sbctl create-keys`, `sbctl enroll-keys -m` with firmware in setup mode) and carry them into the installation with `--extra-files` when the bootloader phase needs them. nixos-anywhere has no secure-boot support of its own.

## Stopping conditions

- State the machine, IP address, disk device, and layout, and get confirmation, immediately before nixos-anywhere runs.
- Do not re-run an install that failed at or after the disko phase. The disk is already destroyed; inspect what exists and ask before acting.
- Treat `just updatekeys` as a rewrite of committed secrets: run it only when the user authorized it, and stop if plaintext appears or files outside the expected secret set change.

For a target that is not running this ISO, or when the target's SSH access is already established, the `anywhere` skill covers the same installation.
