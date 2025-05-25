inspect:
  nix run github:bluskript/nix-inspect -- -p .

install hostname target:
  nix run github:nix-community/nixos-anywhere -- \
    --flake .#{{hostname}} \
    --target-host {{target}} \
    --disko-mode disko \

bootstrap hostname disk:
  nix --extra-experimental-features "nix-command flakes" run 'github:nix-community/disko#disko-install' -- --flake .#{{hostname}} --disk main {{disk}}

generate-hardware-config hostname target:
  ssh {{target}} "nix --extra-experimental-features flakes --extra-experimental-features nix-command run github:numtide/nixos-facter" > ./hardwares/{{hostname}}.json

build:
  nh os build .

deploy:
  nh os switch .

deploy-boot:
	nh os boot .

dryrun:
	nixos-rebuild dry-run --flake . --use-remote-sudo

history:
	nix profile history --profile /nix/var/nix/profiles/system

darwin-bootstrap:
	nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake .

darwin-deploy:
	sudo darwin-rebuild switch --flake .

gc:
	# remove all generations older than 7 days
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

	# garbage collect all unused nix store entries
	sudo nix store gc --debug

build-installer:
  nix build .#nixosConfigurations.installer.config.system.build.isoImage
