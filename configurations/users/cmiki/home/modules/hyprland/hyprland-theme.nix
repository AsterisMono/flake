{ pkgs, osConfig, ... }:
let
  cursorPackage = pkgs.capitaine-cursors;
  cursorThemeName = "capitaine-cursors-white";
  cursorSize = 32;
in
{
  home.packages = with pkgs; [
    adw-gtk3
  ];

  # this sets the XCURSOR variables
  home.pointerCursor = {
    package = cursorPackage;
    name = cursorThemeName;
    size = cursorSize;
  };

  gtk = {
    enable = true;

    iconTheme = {
      name = "breeze";
      package = pkgs.kdePackages.breeze-icons;
    };

    cursorTheme = {
      name = cursorThemeName;
      package = cursorPackage;
      size = cursorSize;
    };

    theme = {
      name = "Breeze";
      package = pkgs.kdePackages.breeze-gtk;
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
