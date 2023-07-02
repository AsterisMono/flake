{ pkgs, ... }:

{
  home.packages = with pkgs; [
    python311
    python311Packages.requests
    python311Packages.virtualenv
  ];
}
