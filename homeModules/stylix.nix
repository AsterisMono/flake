{
  system,
  osConfig ? { },
  pkgs,
  ...
}:
let
  darwinStylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    opacity.terminal = 0.9;
    targets.firefox.profileNames = [ "default" ];
    targets.neovim.enable = false;
    targets.zed.enable = false;
    overlays.enable = false;
  };
  linuxStylix = {
    inherit (osConfig.stylix) image base16Scheme;
    cursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 32;
    };
    icons = {
      enable = true;
      package = pkgs.tela-icon-theme;
      dark = "Tela-dark";
      light = "Tela-light";
    };
    opacity.terminal = 0.95;
    targets.firefox.profileNames = [ "default" ];
    targets.neovim.enable = false;
    targets.zed.enable = false;
  };
in
{
  stylix = if system == "aarch64-darwin" then darwinStylix else linuxStylix;
}
