inputs:

let
  flake = inputs.self;
  commonModules = flake.lib.collectFiles ./modules/common;

  desktopModules = [
    ./users/cmiki
    ./modules/desktop/gui
    ./modules/desktop/security.nix
    ./modules/desktop/shell-packages.nix
    ./modules/desktop/bluetooth.nix
  ];

  myNurPackagesModule = {
    nixpkgs.overlays = [
      (final: prev: {
        amono-nur = inputs.myNurPackages.packages."${prev.system}";
      })
    ];
  };

  homeManagerSpecialArgs = {
    flakeLib = flake.lib;
    nvimConfig = inputs.nvim-config;
  };

  mkLinux = { name, isDesktop ? false, arch ? "x86_64", extraModules ? [ ], users ? [ ] }: {
    name = "amono-${name}";
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

        { networking.hostName = "amono-${name}"; }
      ] ++ commonModules ++ (if isDesktop then desktopModules else [ ]) ++ extraModules;
    };
  };
in
{
  configs = builtins.listToAttrs (map mkLinux [
    {
      name = "81yn";
      isDesktop = true;
      extraModules = [
        ./modules/touchpad.nix
      ];
    }

    {
      name="vm-amberdash";
      isDesktop = true;
      extraModules = [
        ./modules/vmtools.nix
      ];
    }

    {
      name = "amberdash";
      isDesktop = true;
      extraModules = [
        ./modules/nvidia.nix
      ];
    }
  ]);
}
