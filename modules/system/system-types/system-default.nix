{ inputs, ... }:
{
  flake.modules.nixos.system-default = {
    # Default modules
    imports = [
      inputs.self.modules.generic.constants
      inputs.self.modules.nixos.nix
      inputs.self.modules.nixos.secrets
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
    ];

    home-manager.sharedModules = [
      inputs.self.modules.generic.constants
      inputs.self.modules.generic.secrets
      inputs.self.modules.home.secrets
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-index-database.homeModules.nix-index
    ];

    # This is too slow
    documentation.man.cache.enable = false;
  };
}
