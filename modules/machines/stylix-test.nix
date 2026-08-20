{ inputs, ... }:
{
  machines.stylix-test = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      i18n
      fonts
      stylix

      firefox
      fish
      kitty
      ly
      neovim
      sway
      waybar

      nvirellia
    ];
    hardware =
      {
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

        environment.sessionVariables.WLR_RENDERER_ALLOW_SOFTWARE = "1";

        networking.hostName = "stylix-test";
        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        services.displayManager = {
          defaultSession = "sway";
          autoLogin = {
            enable = true;
            user = "nvirellia";
          };
        };

        virtualisation = {
          cores = 4;
          diskSize = 16 * 1024;
          graphics = true;
          memorySize = 4 * 1024;
        };
      };
    homeModule = { lib, ... }: {
      wayland.windowManager.sway.config.startup = lib.mkForce [
        {
          command = "autotiling";
          always = true;
        }
        { command = "kitty --title 'Stylix · Neovim' nvim"; }
        { command = "firefox"; }
      ];
    };
  };
}
