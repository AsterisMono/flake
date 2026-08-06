default: deploy

build:
    nh os build

deploy:
    nh os switch

boot:
    nh os boot

dryrun:
    nixos-rebuild dry-run --flake . --sudo -v -L

install hostname target:
    nix run github:nix-community/nixos-anywhere -- \
      --flake .#{{ hostname }} \
      --target-host {{ target }} \
      --copy-host-keys \
      --no-substitute-on-destination \
      --disko-mode disko \

bootstrap hostname disk:
    nix --extra-experimental-features "nix-command flakes" run 'github:nix-community/disko#disko-install' -- --flake .#{{ hostname }} --disk main {{ disk }}

rdeploy hostname target:
    nixos-rebuild --flake .#{{ hostname }} --target-host {{ target }} switch -v -L

generate-hardware-config target:
    ssh {{ target }} "nix --extra-experimental-features nix-command --extra-experimental-features flakes shell nixpkgs#nixos-install-tools -c nixos-generate-config --show-hardware-config --no-filesystems"

gc:
    # remove all generations older than 7 days
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

    # garbage collect all unused nix store entries
    sudo nix store gc --debug

scan-age-key target:
    ssh {{ target }} cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

updatekeys:
    sops updatekeys modules/secrets/* -y
