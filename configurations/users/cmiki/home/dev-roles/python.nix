{ pkgs, ... }:

{
  home.packages = with pkgs; [
    python310
    python310Packages.requests
    python310Packages.virtualenv
    nodePackages.pyright
  ];
}
