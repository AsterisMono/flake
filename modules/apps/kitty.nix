_: {
  flake.modules.homeManager.kitty = { pkgs, lib, ... }: {
    programs.kitty = {
      enable = true;
      settings = {
        mouse_hide_wait = -1;
        cursor_shape = "beam";
        cursor_blink_interval = 0;
        cursor_beam_thickness = 1.2;
        shell = lib.getExe pkgs.fish;
        hide_window_decorations = true;
        background_blur = 1;
      };
    };
  };
}
