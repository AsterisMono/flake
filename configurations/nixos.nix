inputs:

let
  flake = inputs.self;
  homeManagerSpecialArgs = {
    flakeLib = flake.lib;
    nvimConfig = inputs.nvim-config;
  };


  commonModules = flake.lib.collectFiles ./modules/common;

  desktopModules = [
    ./modules/desktop/gui
    ./modules/desktop/security.nix
    ./modules/desktop/shell-packages.nix
    #homeManagerModule
  ];

  myNurPackagesModule = {
    nixpkgs.overlays = [
      (final: prev: {
        amono-nur = inputs.myNurPackages.packages."${prev.system}";
      })
      (import ../overlays/gnome-x11-fractional.nix)
    ];
  };

  mkLinux = { name, isDesktop ? false, arch ? "x86_64", extraModules ? [ ], users ? [ ] }: {
    name = "${name}";
    value = inputs.nixpkgs.lib.nixosSystem {
      system = "${arch}-linux";

      specialArgs = {
        inherit isDesktop arch flake;
        isLinux = true;
      };

      modules = [
        ./hardwares/${name}.nix
        inputs.nur.nixosModules.nur
        myNurPackagesModule

        inputs.home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = homeManagerSpecialArgs;
        }

        { networking.hostName = "amono-${if isDesktop then "desktop" else "cluster"}-${name}"; }
      ] ++ commonModules
        ++ (if isDesktop then desktopModules else [ ])
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
      users = [ "cmiki" ];
    }
    {
      name = "hifumi";
      isDesktop = true;
      extraModules = [];
      users = [ "cmiki" ];
    }
  ]);
}
