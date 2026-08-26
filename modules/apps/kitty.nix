_: {
  flake.modules.homeManager.kitty = { pkgs, lib, ... }: {
    programs.kitty = {
      enable = true;
      settings = {
        # Force Nerd Font private-use glyphs to the dedicated symbols font.
        symbol_map = "U+e000-U+e00a,U+e0a0-U+e0a2,U+e0a3,U+e0b0-U+e0b3,U+e0b4-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b7,U+e700-U+e8ef,U+ea60-U+ec1e,U+ed00-U+efce,U+f000-U+f2ff,U+f300-U+f381,U+f400-U+f533,U+f0001-U+f1af0 Symbols Nerd Font Mono";
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
