{ config, pkgs, ... }:

{

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs;[
    waybar
    mako
    wofi
    libnotify
    hyprpaper
    hyprshot
    kitty
    kdePackages.polkit-kde-agent-1
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

}