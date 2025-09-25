{ pkgs, ... }:
let
  feishu-nixpak = pkgs.lib.mkNixPak {
    config =
      { sloth, ... }:
      {
        imports = [
          ../_nixpakModules/gui-base.nix
          ../_nixpakModules/network.nix
        ];
        app.package = pkgs.feishu;
        flatpak.appId = "cn.feishu.Feishu";
        bubblewrap = {
          sockets = {
            x11 = false;
            wayland = true;
            pipewire = true;
          };
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.config/LarkShell")
          ];
          bind.ro = [
            sloth.xdgDownloadDir
            (sloth.concat' sloth.homeDir "Pictures/Screenshots")
          ];
        };
        dbus.policies = {
          "org.gnome.keyring" = "talk";
          "org.freedesktop.secrets" = "talk";
          "org.gnome.ScreenSaver" = "talk";
          "org.gnome.Shell.Screencast" = "talk";
          "org.freedesktop.Notifications" = "talk";
        };
      };
  };
in
{
  home.packages = [ feishu-nixpak.config.env ];

  programs.niri.settings.window-rules = [
    {
      matches = [
        {
          app-id = "^Bytedance-feishu$";
          title = "飞书";
        }
      ];
      default-window-height.proportion = 0.8; # Fcitx5 panel offset
    }
  ];
}
