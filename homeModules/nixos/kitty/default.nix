_:

{
  programs.kitty = {
    shellIntegration = {
      enableFishIntegration = true;
      mode = "no-cursor";
    };
    settings = {
      cursor_shape = "block";
      cursor_blink_interval = 0;
      background_opacity = "0.7";
    };
    font = {
      name = "FiraCode Nerd Font Mono Ret";
    };
    extraConfig = builtins.readFile ./everforest.conf;
  };
}
