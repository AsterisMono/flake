_: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  stylix.targets.waybar.addCss = false;
}
