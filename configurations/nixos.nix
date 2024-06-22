inputs:

let
  flake = inputs.self;

  commonModules = flake.lib.collectFiles ./modules/common;
  desktopModules = [
    ./modules/desktop/gui
    ./modules/desktop/hardware/bluetooth.nix
    ./modules/desktop/shell-packages.nix
    ./modules/desktop/sudo-nopasswd.nix
    ./modules/desktop/proxy/mihomo.nix
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

  getHomeManagerModule = isDesktop:
    if isDesktop then [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          flake = inputs.self;
          inherit isDesktop;
        };
      }
    ] else [];

  mkLinux = { name, isDesktop ? false, arch ? "x86_64", diskoEnabled ? false, dmModule ? "", extraModules ? [ ], users }: 
  let
    system = "${arch}-linux";
  in
  {
    inherit name;
    value = inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit isDesktop arch flake;
        inherit (inputs) secrets;
        isLinux = true;
        # Roll unstable software with pkgs-unstable
        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [
        ./modules/hardwares/${name}.nix
        inputs.nur.nixosModules.nur
        overlayModule

        { networking.hostName = name; }
      ] ++ commonModules
        ++ (if isDesktop then desktopModules else serverModules)
        ++ (if diskoEnabled then [ inputs.disko.nixosModules.disko ] else [])
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
      diskoEnabled = false;
      dmModule = "hyprland";
      extraModules = [
        ./modules/desktop/hardware/amdgpu.nix
        # ./modules/extra/distrobox.nix
      ];
      users = [
        "cmiki"
      ];
    }
  ]);
}
