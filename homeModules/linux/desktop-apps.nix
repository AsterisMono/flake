{ pkgs, unstablePkgs, ... }:
let
  extraPackages = with pkgs;[
    dbeaver-bin
  ];
in
{
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
}
