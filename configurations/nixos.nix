inputs:

let
  flake = inputs.self;

  commonModules = flake.lib.collectFiles ./modules/common;
  desktopModules = [
    ./modules/desktop/gui
    ./modules/desktop/hardware/bluetooth.nix
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

  getHomeManagerModule = isDesktop:
    if isDesktop then [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          nvimConfig = inputs.nvim-config;
          flake = inputs.self;
          inherit isDesktop;
        };
      }
    ] else [];

  mkLinux = { name, isDesktop ? false, arch ? "x86_64", diskPattern ? false, dmModule ? "", extraModules ? [ ], users ? [ "cmiki" ] }: {
    name = "${name}";
    value = inputs.nixpkgs.lib.nixosSystem {
      system = "${arch}-linux";

      specialArgs = {
        inherit isDesktop arch flake;
        isLinux = true;
      };

      modules = [
        ./modules/hardwares/${name}
        inputs.agenix.nixosModules.default
        inputs.nur.nixosModules.nur
        overlayModule
        secretModule

        { networking.hostName = name; }
      ] ++ commonModules
        ++ (if isDesktop then desktopModules else serverModules)
        ++ (if diskPattern then [ inputs.disko.nixosModules.disko ] else [])
        ++ (if dmModule != "" then [ ./modules/desktop/gui/dms/${dmModule}.nix ] else [])
        ++ getHomeManagerModule isDesktop
        ++ extraModules
        ++ (map (u: ./users/${u}) users);
    };
  };
in
{
  configs = builtins.listToAttrs (map mkLinux [
    {
      name = "luminara";
      isDesktop = true;
      diskPattern = true;
      dmModule = "hyprland";
      extraModules = [
        ./modules/desktop/hardware/amdgpu.nix
      ];
    }
  ]);
}
