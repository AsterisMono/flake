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
  ssh {{target}} "nixos-generate-config --show-hardware-config --no-filesystems" > ./hardwares/{{hostname}}.nix

build:
  nh os build .

deploy:
  nh os switch .

boot:
	nh os boot .

dryrun:
	nixos-rebuild dry-run --flake . --use-remote-sudo

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