{
  pkgs,
  lib,
  ...
}:
{
  services.xserver = {
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };

    desktopManager.gnome.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    gnome-maps
    simple-scan
    yelp
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  environment.systemPackages =
    (with pkgs.gnomeExtensions; [
      appindicator
      clipboard-indicator
      dash-to-dock
      system-monitor
      xremap
      blur-my-shell
      kimpanel
    ])
    ++ (with pkgs; [
      gnome-tweaks
      gnome-browser-connector
    ]);

  # Override pulseaudio
  # I have no idea who enabled this
  services.pulseaudio.enable = lib.mkForce false;
}
