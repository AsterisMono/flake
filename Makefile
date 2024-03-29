 
############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

deploy:
	nixos-rebuild switch --flake . --use-remote-sudo
	echo "systemctl --user start agenix.service"

debug:
	nixos-rebuild switch --flake . --use-remote-sudo --show-trace --verbose

dryrun:
	nixos-rebuild dry-run --flake . --use-remote-sudo

update:
	nix flake update

history:
	nix profile history --profile /nix/var/nix/profiles/system

force-deploy:
	nixos-rebuild switch --flake . --use-remote-sudo --option eval-cache false
	echo "systemctl --user start agenix.service"

gc:
	# remove all generations older than 7 days
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

	# garbage collect all unused nix store entries
	sudo nix store gc --debug
