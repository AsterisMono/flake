{ pkgs, ... }:
let
  wemeet-nixpak = pkgs.lib.mkNixPak {
    config =
      { sloth, ... }:
      {
        imports = [
          ../_nixpakModules/gui-base.nix
          ../_nixpakModules/network.nix
        ];
        app.package = pkgs.wemeet;
        flatpak.appId = "com.tencent.wemeet";
        bubblewrap = {
          sockets = {
            x11 = false;
            wayland = true;
            pipewire = true;
          };
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.local/share/wemeetapp")
          ];
        };
        dbus.policies = {
          "org.gnome.Shell.Screencast" = "talk";
          "org.freedesktop.Notifications" = "talk";
          "org.kde.StatusNotifierWatcher" = "talk";
        };
      };
  };
in
{
  home.packages = [ wemeet-nixpak.config.env ];

  programs.niri.settings.window-rules = [
    {
      matches = [
        {
          app-id = "^wemeetapp$";
          title = "腾讯会议";
        }
      ];
      open-floating = false;
    }
    {
      matches = [
        {
          app-id = "^wemeetapp$";
          title = "EmojiFloatWnd";
        }
      ];
      default-floating-position = {
        relative-to = "top-right";
        x = 72;
        y = 135;
      };
    }
  ];
}
