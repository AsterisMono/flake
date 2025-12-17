{
  lib,
  system,
  pkgs,
  unstablePkgs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    package = if (system == "aarch64-darwin") then null else unstablePkgs.ghostty;
    enableFishIntegration = true;
    settings = {
      font-style = "Retina";
      mouse-hide-while-typing = true;
      cursor-style = "bar";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor";
      adjust-cursor-thickness = 2;
      adjust-cell-height = 1;
      command = lib.getExe pkgs.fish;
      macos-titlebar-proxy-icon = "hidden";
      background-blur = true;
    };
  };
}
