{ pkgs, ... }:
{
  home.packages = [ pkgs.feishu ];

  programs.niri.settings.window-rules =
    let
      app-id = "^Bytedance-feishu$";
    in
    [
      {
        matches = [
          {
            inherit app-id;
            title = "飞书";
          }
        ];
        default-window-height.proportion = 0.8; # Fcitx5 panel offset
      }
      {
        matches = [
          {
            inherit app-id;
            title = "图片";
          }
        ];
        open-floating = true;
        open-fullscreen = false;
        default-window-height.proportion = 0.65;
        default-column-width.proportion = 0.65;
      }
    ];
}
