inputs:

let
  flake = inputs.self;
  commonModules = flake.nixUtils.collectFiles ./modules/common;

  desktopModules = [
    ./users/cmiki
    ./modules/gui
    ./modules/security.nix
    ./modules/desktop-apps # TODO: Convert to role-based module
  ];

  mkLinux = { name, isDesktop ? false, arch ? "x86_64", extraModules ? [ ] }: {
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
      ] ++ commonModules ++ (if isDesktop then desktopModules else [ ]) ++ extraModules;
      specialArgs = {
        inherit isDesktop arch flake;
        isLinux = true;
      };
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
  ]);
}
