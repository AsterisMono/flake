{ lib, ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
      font_size = lib.mkForce 11.0;
      cursor_shape = "beam";
      cursor_blink_interval = 0;
      cursor_beam_thickness = 1.2;
      shell_integration = "enabled";
    };
  };
}
