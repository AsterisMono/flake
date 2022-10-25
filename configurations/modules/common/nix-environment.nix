{ config, pkgs, ... }:

{

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "22.11";

}