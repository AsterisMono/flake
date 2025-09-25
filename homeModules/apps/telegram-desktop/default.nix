{ unstablePkgs, ... }:
{
  home.packages = [ unstablePkgs.telegram-desktop ];

  programs.niri.settings.window-rules =
    let
      app-id = "^org\.telegram\.desktop$";
    in
    [
      {
        matches = [
          { inherit app-id; }
        ];
        open-on-workspace = "messengers";
        block-out-from = "screencast";
      }
      {
        matches = [
          {
            inherit app-id;
            title = "^Media viewer$";
          }
        ];
        open-floating = true;
        open-fullscreen = false;
        default-window-height.proportion = 0.65;
        default-column-width.proportion = 0.65;
      }
    ];
}
