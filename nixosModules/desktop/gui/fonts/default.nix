{ pkgs, ... }:
{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override {
        fonts = [ "FiraCode" "Hack" "JetBrainsMono" "UbuntuMono" ];
      })
      # hack-font
      inter
      # liberation_ttf
      # twemoji-color-font
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-extra
      # roboto
      # wqy_microhei
      # wqy_zenhei
      # meslo-lg
      fira-code
      font-awesome
      font-awesome_5
      font-awesome_4
      flakePackages.torus-font
    ];
    enableGhostscriptFonts = true;
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      localConf = builtins.readFile ./fonts.conf;
    };
  };
}
