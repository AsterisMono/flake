{
  pkgs,
  lib,
  ...
}:
{
  services.xserver = {
    enable = true;

    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };

    desktopManager.gnome.enable = true;

    excludePackages = with pkgs; [
      xterm
    ];
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

  programs.xwayland.enable = true;
  programs.xwayland.package = pkgs.xwayland;

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  environment.systemPackages =
    (with pkgs.gnomeExtensions; [
      appindicator
      dash-to-dock
      system-monitor
      xremap
      blur-my-shell
      kimpanel
    ])
    ++ (with pkgs; [
      gnome-tweaks
      gnome-remote-desktop
      gnome-browser-connector
    ]);

  # Override pulseaudio
  # I have no idea who enabled this
  services.pulseaudio.enable = lib.mkForce false;

  # RDP Support
  services.gnome.gnome-remote-desktop.enable = true;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
  services.xrdp.openFirewall = true;
}
