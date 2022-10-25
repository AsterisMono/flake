{ config, pkgs, ... }:

{

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    binaryCaches = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
  };

  nixpkgs.config.allowUnfree = true;

  system.copySystemConfiguration = true;

  system.stateVersion = "22.05";

}
