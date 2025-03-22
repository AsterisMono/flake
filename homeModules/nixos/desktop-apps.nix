{
  osConfig,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
let
  extraPackages =
    with pkgs;
    [
      dbeaver-bin
      fractal
    ]
    ++ (with unstablePkgs; [
      code-cursor
      warp-terminal
      xpipe
      telegram-desktop
      obsidian
    ]);
in
{
  config = lib.mkIf osConfig.amono.homeManager.installGraphicalApps {
    home.packages = extraPackages;

    programs.vscode = {
      enable = true;
      package = unstablePkgs.vscode.fhs;
    };

    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
      ];
    };
  };
}
