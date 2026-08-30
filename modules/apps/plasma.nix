_: {
  flake.modules.nixos.plasma =
    { pkgs, ... }:
    {
      services.desktopManager.plasma6.enable = true;
      services.displayManager.plasma-login-manager.enable = true;

      environment.systemPackages = [ pkgs.kdePackages.kleopatra ];
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        discover
        elisa
        khelpcenter
        konsole
        kwin-x11
        plasma-browser-integration
        plasma-keyboard
        plasma-workspace-wallpapers
        qtvirtualkeyboard
      ];
    };
}
