{
  osConfig,
  inputs,
  system,
  lib,
  ...
}:
let
  vicinaePkg = inputs.vicinae.packages.${system}.default;
  vicinae = lib.getExe vicinaePkg;
in
{
  imports = [ inputs.vicinae.homeManagerModules.default ];

  services.vicinae = {
    enable = true;
    package = inputs.vicinae.packages.${system}.default;
  };

  systemd.user.services.vicinae.Service.Environment = [
    "PATH=/etc/profiles/per-user/cmiki/bin"
  ];

  xdg.configFile."vicinae/vicinae.json".force = true;

  dconf.settings = lib.mkIf osConfig.services.desktopManager.gnome.enable {
    "org/gnome/desktop/wm/keybindings" = {
      switch-input-source = [ "@as []" ];
      switch-input-source-backward = [ "@as []" ];
    };
    "org/gnome/shell/keybindings" = {
      toggle-message-tray = [ "@as []" ];
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>space";
      command = "${vicinae} toggle";
      name = "Vicinae";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>v";
      command = "${vicinae} deeplink vicinae://extensions/vicinae/clipboard/history";
      name = "Vicinae clipboard";
    };
  };
}
