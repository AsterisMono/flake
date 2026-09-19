---
name: install-machine
description: Install a machine from this flake onto a target booted from this flake's installer ISO using nixos-anywhere. Use when provisioning new or wiped hardware from the installer image; not for ordinary deploys of a machine that is already running.
disable-model-invocation: true
---

# Install a machine from the installer ISO

This erases the target's disks. Confirm the machine name, IP address, disk device, and layout before running nixos-anywhere.

## Collect first

- Ask the user for the target's IP address and whether the target is a workstation or a server. Use `root` as the SSH user unless they say otherwise.
- Take the layout from the machine's `diskoConfig`, and confirm the name is exported with `nix eval .#diskoConfigurations --apply builtins.attrNames`. Workstations and servers are expected to differ — `xfs-workstation` has an ESP, 32G swap, and a LUKS root, `ext4-server-efi` has an ESP and a plain ext4 root — but do not assume that from the machine's role alone: layouts move between machines and a server layout may not be exported yet.

## Environment facts

- The target boots this repository's installer ISO (`just build-installer-iso`). It ships `sbctl` and an SSH daemon with `PermitRootLogin = yes` and the maintainer's public key in root's `authorizedKeys`, so `ssh root@<ip>` works without a password.
- The target never carries a checkout of this repository, and it does not need one. Every repo command runs on the workstation; only target-local tools such as `sbctl` run on the target.
- `nixos-anywhere` skips its kexec phase against a target whose `/etc/os-release` reports `VARIANT_ID=installer`, which this ISO does. Then the target's `/run` survives and a passphrase written there before the run is still readable when disko formats. Against any other target kexec replaces the live environment and `/run` with it, so the passphrase must arrive through `--disk-encryption-keys <remote-path> <local-source>`, which is uploaded after kexec and before disko.
- With `--disko-mode disko`, disko formats `disko.devices.disk.main.device` from the machine's `hardware` block, so that path must already point at the target disk.
- The flake is evaluated on the workstation, so new machine and layout files must be staged with `git add` before Nix can see them.
- The installed machine has no repository checkout and is not expected to grow one. Later changes are pushed from a workstation with `just rdeploy <machine> <target>`, or `just install` for another full installation.

## Workflow

1. Define the machine in `modules/machines/<machine>.nix`: import the roles and aspects it needs, set `diskoConfig` to the chosen layout, and set `hardware.disko.devices.disk.main.device` to the target disk's `/dev/disk/by-id/...` path (read it on the target with `ls -l /dev/disk/by-id/`). Stage the file and confirm it evaluates: `nix eval --raw .#nixosConfigurations.<machine>.config.system.build.toplevel.drvPath`.
2. If the layout has a LUKS root, get a passphrase file on the workstation and never let an unread passphrase reach disko:
   - Interactive: `just prompt-luks-password <machine>` in the development shell, which provides the graphical pinentry. It opens a dialog, writes a fresh user-owned 0600 file, and prints its path.
   - New machine: `just generate-luks-password <machine>` creates a random passphrase and stores `NixOS <machine> LUKS root` in the `NixOS` vault.
   - In either case, read the passphrase from the vault into a fresh 0600 file and prove the read worked before installing, because a process substitution like `<(op read …)` hides an expired session or a missing item, and disko destroys filesystems before it starts formatting:
     ```
     umask 077
     dest=$(mktemp --tmpdir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}" "nixos-<machine>-luks-password.XXXXXXXX")
     op read 'op://NixOS/NixOS <machine> LUKS root/password' > "$dest"
     test -s "$dest"
     ```
     A machine whose passphrase only exists in someone's head skips the vault step; `prompt-luks-password` already wrote the file. Pass `"$dest"` as the third argument to `install`, and delete it when the installation is done.
3. Boot the target from the installer ISO and bring up networking with `nmtui`. Then confirm access from the workstation with `ssh root@<ip> true`. If the key is refused, stop and report instead of improvising credentials.
4. If the machine consumes sops secrets, enroll its host age recipient before installing: `just scan-age-key root@<ip>`, then add that anchor to `.sops.yaml` both in `keys` and in the recipient list of the `creation_rules` entry that matches the machine's secret files. An anchor alone enrolls nothing. Run `just updatekeys` (this rewrites the encrypted documents and needs explicit authorization) and commit the result. `--copy-host-keys` carries the same host keys into the installation, so the enrolled recipient stays valid.
5. Machines that import the `secure-boot` aspect (currently asymmetry) need their `sbctl` keys before the bootloader is installed, because lanzaboote signs the files it installs. The ISO ships `sbctl`, and enrollment writes firmware variables, so run it on the target and then carry the bundle to the workstation:
   - On the target, with firmware in setup mode: `sbctl create-keys`, then `sbctl enroll-keys -m`. Never run this on the workstation; it would enroll keys into the wrong machine's firmware.
   - Copy the bundle into the shape `--extra-files` expects, so the local directory mirrors the installation root: `mkdir -p <local-dir>/var/lib && ssh root@<ip> tar -C /var/lib -cf - sbctl | tar -C <local-dir>/var/lib -xf -`.
   - Install with a nixos-anywhere invocation that carries it: `--extra-files <local-dir>`. `just install` cannot forward that option.
6. Install the machine. For a server layout: `just install <machine> root@<ip>`. For a LUKS layout: `just install <machine> root@<ip> <passphrase-file>`, where the file came from step 2; the recipe uploads it to `/run/luks-password` in the installer environment before disko runs. Never put the passphrase itself in the command line.
7. Verify from the installed machine, which has no checkout: it boots, and with a LUKS root it prompts for the passphrase. A `xfs-workstation` machine also reports the 32G partition in `swapon --show` and carries `resume=/dev/disk/by-partlabel/disk-main-swap` in `/proc/cmdline`; a plain ext4 server layout has neither.

## Stopping conditions

- State the machine, IP address, disk device, and layout, and get confirmation, immediately before nixos-anywhere runs.
- Do not re-run an install that failed at or after the disko phase. The disk is already destroyed; inspect what exists and ask before acting.
- Treat `just updatekeys` as a rewrite of committed secrets: run it only when the user authorized it, and stop if plaintext appears or files outside the expected secret set change.

For a target that is not running this ISO, or when the target's SSH access is already established, the `anywhere` skill covers the same installation.
