{ pkgs, ... }:
{
  stylix = {
    enable = true;
    image = pkgs.fetchurl {
      name = "three-bicycles.jpg";
      url = "https://unsplash.com/photos/hwLAI5lRhdM/download?ixid=M3wxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNzE2MzYxNDcwfA&force=true";
      hash = "sha256-S0MumuBGJulUekoGI2oZfUa/50Jw0ZzkqDDu1nRkFUA=";
    };
    polarity = "light";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-light.yaml";
    override = {
      base0D = "#f2ae49";
      base0A = "#36a3d9";
    };
    fonts = {
      monospace = {
        package =
          pkgs.nerdfonts.override {
            fonts = [ "FiraCode" ];
          };
        name = "FiraCode Nerd Font Mono Ret";
      };
    };
    cursor.size = 24;
    opacity.terminal = 0.9;
  };
  home-manager.sharedModules = [
    {
      stylix.targets = {
        vscode.enable = false;
        neovim.enable = false;
      };
      stylix.iconTheme = {
        enable = true;
        package = pkgs.papirus-icon-theme.override {
          color = "yellow";
        };
        light = "Papirus";
        dark = "Papirus";
      };
    }
  ];
}
