flake:

flake.inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit (flake.inputs) secrets;
  };
  modules = [
    ({ modulesPath, ... }: {
      imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
      amono.proxy.enable = true;
    })
    ../nixosModules/common/proxy.nix
  ];
}
