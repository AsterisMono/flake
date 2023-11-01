inputs:

let
  flake = inputs.self;

  commonModules = flake.lib.collectFiles ./modules/common;
  desktopModules = [
    ./modules/desktop/gui
    ./modules/desktop/shell-packages.nix
    ./modules/desktop/sudo-nopasswd.nix
  ];
  serverModules = flake.lib.collectFiles ./modules/server;

  overlayModule = {
    nixpkgs.overlays = [
      (final: prev: {
        amono-nur = inputs.myNurPackages.packages."${prev.system}";
      })
      (import "${flake}/overlays/gnome-x11-fractional.nix")
    ];
  };
  secretModule = {
    age.secrets.tailscaleAuthkey.file = ../secrets/tailscale-authkey.age;
  };

  mkLinux = { name, isDesktop ? false, arch ? "x86_64", extraModules ? [ ], users ? [ "cmiki" ] }: {
    name = "${name}";
    value = inputs.nixpkgs.lib.nixosSystem {
      system = "${arch}-linux";

      specialArgs = {
        inherit isDesktop arch flake;
        isLinux = true;
      };

      modules = [
        ./hardwares/${name}.nix
        inputs.agenix.nixosModules.default
        inputs.nur.nixosModules.nur
        overlayModule
        secretModule
        inputs.home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            nvimConfig = inputs.nvim-config;
            inherit flake isDesktop;
          };
        }

        { networking.hostName = name; }
      ] ++ commonModules
        ++ (if isDesktop then desktopModules else serverModules)
        ++ extraModules
        ++ (map (u: ./users/${u}) users);
    };
  };
in
{
  configs = builtins.listToAttrs (map mkLinux [
    {
      name = "amberdash";
      isDesktop = true;
      extraModules = [
        ./modules/desktop/hardware/nvidia.nix
        ./modules/desktop/hardware/bluetooth.nix
      ];
    }
    {
      name = "hifumi";
      isDesktop = true;
      extraModules = [ ] ++ serverModules;
    }
  ]);
}
