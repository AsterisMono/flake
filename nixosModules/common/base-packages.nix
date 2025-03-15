{
  config,
  pkgs,
  lib,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
    gnumake
    gcc
  ];

  programs.git = {
    enable = true;
  };
}
