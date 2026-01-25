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
    ssh {{ target }} "nix --extra-experimental-features nix-command --extra-experimental-features flakes shell nixpkgs#nixos-install-tools -c nixos-generate-config --show-hardware-config --no-filesystems" > ./hardwares/{{ hostname }}.nix

build:
    nixos-rebuild build --flake . --sudo -v -L

deploy:
    nixos-rebuild switch --flake . --sudo -v -L

boot:
    nixos-rebuild boot --flake . --sudo -v -L

dryrun:
    nixos-rebuild dry-run --flake . --sudo -v -L

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
    cp ~/.config/iterm2/com.googlecode.iterm2.plist ./homeModules/apps/iterm2/com.googlecode.iterm2.plist

zed_config_dir := "./homeModules/apps/zed"

update-zed:
    cat ~/.config/zed/settings.json | \
        npx strip-json-comments-cli | \
        jq '(.. | objects | select(has("context7_api_key"))) .context7_api_key = "YOUR_API_KEY_HERE"' \
        > {{ zed_config_dir }}/settings.json
    cat ~/.config/zed/keymap.json | npx strip-json-comments-cli > {{ zed_config_dir }}/keymap.json
    npx prettier --parser json --trailing-comma none --write {{ zed_config_dir }}/*.json

scan-age-key target:
    ssh {{ target }} cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

updatekeys:
    sops updatekeys secrets/* -y

rdeploy:
    deploy

rdeploy-host hostname:
    deploy .#{{ hostname }}

rdeploy-host-bare hostname target:
    nixos-rebuild --flake .#{{ hostname }} --target-host {{ target }} switch -v -L

generate-wg-keys:
    wg genkey | tee privatekey | wg pubkey > publickey

git-agecrypt-activate:
    git-agecrypt init && git-agecrypt config add -i ~/.config/sops/age/keys.txt && git checkout main && git restore .

git-agecrypt-add file:
    git-agecrypt config add -r "age10rmq9vcjjpxpl7qx2qc9nh6xvr0ktdjphq7w6mz9zwlz6kxxfprqfrz7gk" -p {{ file }} && echo "{{ file }} filter=git-agecrypt diff=git-agecrypt" >> .gitattributes
