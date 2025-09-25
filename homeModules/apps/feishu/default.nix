{ pkgs, ... }:
{
  home.packages = [ pkgs.feishu ];

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
