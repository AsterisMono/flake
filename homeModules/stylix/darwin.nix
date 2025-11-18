{ pkgs, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-dawn.yaml";
    opacity.terminal = 0.9;
    targets.firefox.profileNames = [ "default" ];
    targets.neovim.enable = false;
    overlays.enable = false;
  };
}
