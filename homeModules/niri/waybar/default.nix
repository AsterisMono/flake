_: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ./style.css;
  };

  xdg.configFile."waybar/config.jsonc".source = ./config.jsonc;

  stylix.targets.waybar.enable = false;
}
