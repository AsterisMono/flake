{ inputs, ... }:
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://mirror.sjtu.edu.cn/flathub";
      }
    ];

    packages = [
      "com.github.tchx84.Flatseal"
      "cn.feishu.Feishu"
      "com.qq.QQ"
      "com.tencent.WeChat"
      "com.tencent.wemeet"
      "io.github.qier222.YesPlayMusic"
    ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    overrides = {
      global = {
        Context.filesystems = [
          "/nix/store:ro"
          "xdg-config/fontconfig:ro"
        ];
      };
    };
  };
}
