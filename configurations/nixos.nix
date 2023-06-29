inputs:

let
  commonModules = [
    ./modules/common/base-packages.nix
    ./modules/common/boot.nix
    ./modules/common/i18n.nix
    ./modules/common/networking.nix
    ./modules/common/nix-environment.nix
    ./users/cmiki
  ];

  desktopModules = [
    ./modules/gui
    ./modules/security.nix
    ./modules/desktop-apps # TODO: Convert to role-based module
  ];

  mkLinux = { name, desktop ? false, arch ? "x86_64", extraModules ? [ ] }: {
    name = "amono-${name}";
    value = inputs.nixpkgs.lib.nixosSystem {
      system = "${arch}-linux";
      modules = [
        ./hardwares/${name}.nix
        inputs.nur.nixosModules.nur

        inputs.home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

        { networking.hostName = "amono-${name}"; }
      ] ++ commonModules ++ (if desktop then desktopModules else [ ]) ++ extraModules;
      specialArgs = {
        inherit inputs arch;
        flake = inputs.self;
        isLinux = true;
      };
    };
  };
in
{
  configs = builtins.listToAttrs (map mkLinux [
    {
      name = "81yn";
      desktop = true;
      extraModules = [
        ./modules/touchpad.nix
      ];
    }

    {
      name="vm-amberdash";
      desktop = true;
      extraModules = [
        ./modules/vmtools.nix
      ];
    }
  ]);
}
