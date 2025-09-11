{ pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (old: {
      version = "0.14.0";
      src = pkgs.fetchFromGitHub {
        owner = "stkth";
        repo = "Waybar";
        rev = "3060141a65fad5a79c7f8375c1e363d1e6e34f58";
        hash = "sha256-OJ8fK4KzIfh1nQphZOlQj/iBDlh7AK9LDPxuneJ7k6w=";
      };
    });
    systemd.enable = true;
    style = ./style.css;
  };

  xdg.configFile."waybar/config.jsonc".source = ./config.jsonc;

  stylix.targets.waybar.enable = false;

  # MPRIS
  services.playerctld.enable = true;
}
