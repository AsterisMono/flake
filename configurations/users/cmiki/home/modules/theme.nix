{ pkgs, osConfig, ... }:
{
  home.packages = with pkgs; [
    adw-gtk3
  ];

  gtk = {
    enable = true;

    iconTheme = {
      name = "Vimix-Jade";
      package = pkgs.vimix-icon-theme;
    };

    cursorTheme = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };    
  };

  dconf.settings = pkgs.lib.mkIf (osConfig.services.xserver.desktopManager.gnome.enable == true) {
      "org/gnome/desktop/interface" = {
        font-name = "更纱黑体 UI SC 11";
        document-font-name = "更纱黑体 UI SC 11";
        gtk-theme = "adw-gtk3";
      };
      
      "org/gnome/desktop/wm/preferences" = {
        titlebar-font = "更纱黑体 UI SC Bold 11";
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        click-action = "minimize";
        transparency-mode = "FIXED";
      };
    };
}
