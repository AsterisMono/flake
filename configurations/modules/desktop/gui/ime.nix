{ pkgs, ... }:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      # no mkIfs can be used. sad.
      waylandFrontend = true;
      plasma6Support = true;
      addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-configtool
      ];
    };
  };
}
