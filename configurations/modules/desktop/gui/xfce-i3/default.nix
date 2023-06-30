{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };

    displayManager.defaultSession = "xfce";

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
  };
}
