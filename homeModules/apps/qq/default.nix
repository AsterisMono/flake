{
  pkgs,
  unstablePkgs,
  ...
}:
let
  qq-nixpak = pkgs.lib.mkNixPak {
    config =
      { sloth, ... }:
      {
        app = {
          package = unstablePkgs.qq;
          binPath = "bin/qq";
        };
        flatpak.appId = "com.qq.QQ";

        imports = [
          ../_nixpakModules/common.nix
          ../_nixpakModules/gui-base.nix
          ../_nixpakModules/network.nix
        ];

        # list all dbus services:
        #   ls -al /run/current-system/sw/share/dbus-1/services/
        #   ls -al /etc/profiles/per-user/ryan/share/dbus-1/services/
        dbus.policies = {
          # System tray icon
          "org.freedesktop.Notifications" = "talk";
          "org.freedesktop.ScreenSaver" = "talk";
          "org.kde.StatusNotifierWatcher" = "talk";
          # File Manager
          "org.freedesktop.FileManager1" = "talk";
          # Uses legacy StatusNotifier implementation
          "org.kde.*" = "own";
        };
        bubblewrap = {
          # To trace all the home files QQ accesses, you can use the following nushell command:
          #   just trace-access qq
          # See the Justfile in the root of this repository for more information.
          bind.rw = [
            sloth.xdgDocumentsDir
            sloth.xdgDownloadDir
            sloth.xdgMusicDir
            sloth.xdgVideosDir
          ];
          sockets = {
            x11 = false;
            wayland = true;
            pipewire = true;
          };
        };
      };
  };
in
{
  home.packages = [ qq-nixpak.config.env ];

  programs.niri.settings.window-rules =
    let
      app-id = "^QQ$";
    in
    [
      {
        matches = [
          {
            inherit app-id;
            title = "QQ";
          }
        ];
        open-floating = false;
        default-window-height.proportion = 0.8;
      }
      {
        matches = [
          {
            inherit app-id;
            title = "^(图片查看)|(视频播放)器$";
          }
        ];
        open-floating = true;
        open-fullscreen = false;
        default-window-height.proportion = 0.65;
        default-column-width.proportion = 0.65;
      }
      {
        matches = [
          { inherit app-id; }
        ];
        block-out-from = "screencast";
      }
    ];
}
