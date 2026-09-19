---
name: install-machine
description: Install a machine from this flake onto a target booted from this flake's installer ISO using nixos-anywhere. Use after init-machine has committed the machine definition, its hardware facts, and any host age recipient; not for ordinary deploys of a machine that is already running.
disable-model-invocation: true
---

# Install a machine from the installer ISO

This erases the target's disks. Confirm the machine name, IP address, disk device, and layout before running nixos-anywhere.

## Prerequisites

The `init-machine` skill prepares a new target: SSH access to the running ISO, the machine definition in `modules/machines/<machine>.nix` with the target's hardware facts, and the host age recipient when the machine consumes sops secrets. Confirm all of it is committed before starting. Preparation from an earlier boot of the target is stale; redo it from the current boot instead of installing against it.

- Ask the user for the target's IP address and whether the target is a workstation or a server. Use `root` as the SSH user unless they say otherwise.
- Take the layout from the machine's `diskoConfig`, and confirm the name is exported with `nix eval .#diskoConfigurations --apply builtins.attrNames`. Workstations and servers are expected to differ — `xfs-workstation` has an ESP, 32G swap, and a LUKS root, `ext4-server-efi` has an ESP and a plain ext4 root — but do not assume that from the machine's role alone: layouts move between machines and a server layout may not be exported yet.

## Environment facts

- The target boots this repository's installer ISO (`just build-installer-iso`). It ships `sbctl` and an SSH daemon with `PermitRootLogin = yes` and the maintainer's public key in root's `authorizedKeys`, so `ssh root@<ip>` works without a password.
- The target never carries a checkout of this repository, and it does not need one. Every repo command runs on the workstation; only target-local tools such as `sbctl` run on the target.
- Installs are normally driven from one of the workstations, currently asymmetry and parallax. Run `hostname` first: the machine you are on decides whether this checkout, the enrolled host identities, and the LUKS and Secure Boot material are at hand, and only a machine that already reads a secret document can re-key one that has no maintainer recipient.
- `nixos-anywhere` skips its kexec phase against a target whose `/etc/os-release` reports `VARIANT_ID=installer`, which this ISO does. Then the target's `/run` survives and a passphrase written there before the run is still readable when disko formats. Against any other target kexec replaces the live environment and `/run` with it, so the passphrase must arrive through `--disk-encryption-keys <remote-path> <local-source>`, which is uploaded after kexec and before disko.
- With `--disko-mode disko`, disko formats `disko.devices.disk.main.device` from the machine's `hardware` block, so that path must already point at the target disk.
- The flake is evaluated on the workstation, so new machine and layout files must be staged with `git add` before Nix can see them.
- The installed machine has no repository checkout and is not expected to grow one. Later changes are pushed from a workstation with `just rdeploy <machine> <target>`, or `just install` for another full installation.

## Workflow

1. Confirm the prepared machine still matches the target: `nix eval --raw .#nixosConfigurations.<machine>.config.disko.devices.disk.main.device` must name the disk read from this target. If the machine is not defined, not staged, or still carries placeholder hardware facts, run `init-machine` first.
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
3. Confirm which host identity the installation will end up with, because the enrolled sops recipients follow it. By default `--copy-host-keys` carries the installer's host keys into the installation, so the enrolled recipient must be the one the live ISO reports from `just collect-machine-info root@<ip>`; a reboot of the target regenerates those keys and invalidates the enrollment. To keep a machine's existing identity instead, save its `ssh_host_*_key` and `.pub` files before wiping and pass them through `--extra-files`: nixos-anywhere copies extra files first and does not overwrite an existing host key with the ISO's, so the preserved key wins and the enrolled recipient must be the one derived from it. `just install` cannot forward `--extra-files`, so a preserved identity means the direct nixos-anywhere invocation. Either way, stop when the enrolled recipient and the identity the installation will carry disagree.
4. Machines that import the `secure-boot` aspect (currently asymmetry) need their `sbctl` keys before the bootloader is installed, because lanzaboote signs the files it installs. The ISO ships `sbctl`, and enrollment writes firmware variables, so run it on the target and then carry the bundle to the workstation:
   - On the target, with firmware in setup mode: `sbctl create-keys`, then `sbctl enroll-keys -m`. Never run this on the workstation; it would enroll keys into the wrong machine's firmware.
   - Copy the bundle into the shape `--extra-files` expects, so the local directory mirrors the installation root: `mkdir -p <local-dir>/var/lib && ssh root@<ip> tar -C /var/lib -cf - sbctl | tar -C <local-dir>/var/lib -xf -`.
   - Install with a nixos-anywhere invocation that carries it: `--extra-files <local-dir>`. `just install` cannot forward that option.
5. Install the machine. For a server layout: `just install <machine> root@<ip>`. For a LUKS layout: `just install <machine> root@<ip> <passphrase-file>`, where the file came from step 2; the recipe uploads it to `/run/luks-password` in the installer environment before disko runs. Never put the passphrase itself in the command line. Redirect the run's output to a log file, and watch it in a Herdr pane when the session is Herdr-managed.
6. Verify from the installed machine, which has no checkout: it boots, and with a LUKS root it prompts for the passphrase. A `xfs-workstation` machine also reports the 32G partition in `swapon --show` and carries `resume=/dev/disk/by-partlabel/disk-main-swap` in `/proc/cmdline`; a plain ext4 server layout has neither.

## Watch the log in a Herdr pane

An install runs for tens of minutes, so when this session is Herdr-managed (`HERDR_ENV=1`), give the log its own pane and let the install keep running in the original one. Follow the `herdr` skill for the current CLI; the shape is:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr pane run <pane-id> "tail -f /tmp/install-<machine>.log"
```

Write the install's output to that same log file, read the pane ID from the split response (`.result.pane.pane_id`), and split `down` instead of `right` when the pane is tall or narrow rather than wide. Keep `--no-focus` so the user's focus stays where it was, and close the pane once the install finishes. Without a Herdr session, the log file alone is enough.

## Stopping conditions

- State the machine, IP address, disk device, and layout, and get confirmation, immediately before nixos-anywhere runs.
- Do not re-run an install that failed at or after the disko phase. The disk is already destroyed; inspect what exists and ask before acting.
- Treat a target that rebooted since `init-machine` as unprepared. Its hardware facts may still hold, but its host keys and enrolled recipient do not.
