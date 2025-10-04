{ pkgs, ... }:
{
  home.packages = [ pkgs.moonlight-qt ];

  programs.niri.settings.window-rules =
    let
      app-id = "^com.moonlight_stream.Moonlight$";
    in
    [
      {
        matches = [
          {
            inherit app-id;
            title = "^Moonlight$";
          }
        ];
        open-floating = true;
        default-window-height.proportion = 0.65;
        default-column-width.proportion = 0.65;
      }
      {
        matches = [
          {
            inherit app-id;
            title = "-";
          }
        ];
        default-column-width.proportion = 1.0;
      }
    ];
}
