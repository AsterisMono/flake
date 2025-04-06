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
        imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
        amono.proxy.enable = true;
        amono.tailscale = {
          enable = true;
          ssh.enable = true;
          advertiseTags = [ "installer" ];
          isEphemeral = true;
        };
      }
    )
    ../nixosModules/common/proxy.nix
    ../nixosModules/common/tailscale.nix
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
