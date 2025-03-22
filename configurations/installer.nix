flake:

flake.inputs.nixpkgs.lib.nixosSystem rec {
  system = "x86_64-linux";
  specialArgs = {
    inherit (flake.inputs) secrets;
    inherit flake system;
  };
  modules = [
    (
      { modulesPath, ... }:
      {
        imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-graphical-plasma5.nix") ];
        amono.proxy.enable = true;
      }
    )
    ../nixosModules/common/proxy.nix
    ../nixosModules/common/nix-environment.nix
    (
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          git
          gh
        ];
      }
    )
  ];
}
