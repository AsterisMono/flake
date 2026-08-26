_: {
  flake.modules.homeManager.kitty = { pkgs, lib, ... }: {
    programs.kitty = {
      enable = true;
      extraConfig = ''
        symbol_map U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d4,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+f000-U+f2e0,U+f300-U+f372,U+f400-U+f532,U+f0001-U+f1af0 Symbols Nerd Font Mono
        symbol_map U+2600-U+26FF Noto Color Emoji
      '';
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
