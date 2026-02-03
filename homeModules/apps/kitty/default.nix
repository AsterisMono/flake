{
  lib,
  system,
  unstablePkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    package = if system == "aarch64-darwin" then null else unstablePkgs.firefox;
    settings = {
      font_size = lib.mkForce 11.0;
      cursor_shape = "beam";
      cursor_blink_interval = 0;
      cursor_beam_thickness = 1.2;
      shell_integration = "enabled";
      allow_remote_control = "socket-only";
      macos_option_as_alt = "both";
    };
  };
}
