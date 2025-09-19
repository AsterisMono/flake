inspect:
    nix run github:bluskript/nix-inspect -- -p .

install hostname target:
    nix run github:nix-community/nixos-anywhere -- \
      --flake .#{{ hostname }} \
      --target-host {{ target }} \
      --copy-host-keys \
      --disko-mode disko \

bootstrap hostname disk:
    nix --extra-experimental-features "nix-command flakes" run 'github:nix-community/disko#disko-install' -- --flake .#{{ hostname }} --disk main {{ disk }}

generate-hardware-config hostname target:
    ssh {{ target }} "nixos-generate-config --show-hardware-config --no-filesystems" > ./hardwares/{{ hostname }}.nix

build:
    nixos-rebuild build --flake . --use-remote-sudo -v -L

deploy:
    nixos-rebuild switch --flake . --use-remote-sudo -v -L

boot:
    nixos-rebuild boot --flake . --use-remote-sudo -v -L

dryrun:
    nixos-rebuild dry-run --flake . --use-remote-sudo -v -L

history:
    nix profile history --profile /nix/var/nix/profiles/system

darwin-bootstrap:
    sudo nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake .

darwin-deploy:
    nh darwin switch .

gc:
    # remove all generations older than 7 days
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

    # garbage collect all unused nix store entries
    sudo nix store gc --debug

update-iterm2:
    cp ~/.config/iterm2/com.googlecode.iterm2.plist ./homeModules/iterm2/com.googlecode.iterm2.plist

scan-age-key target:
    ssh {{ target }} cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

updatekeys:
    sops updatekeys secrets/* -y

rdeploy:
    deploy

rdeploy-host hostname:
    deploy .#{{ hostname }}

rdeploy-host-bare hostname target:
    nixos-rebuild --flake .#{{ hostname }} --target-host {{ target }} switch --use-remote-sudo -v -L

generate-wg-keys:
    wg genkey | tee privatekey | wg pubkey > publickey

activate-git-crypt:
    git-agecrypt config add -i ~/.config/sops/age/keys.txt