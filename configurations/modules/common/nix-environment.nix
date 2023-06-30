{ pkgs, ... }:

{

  nix = {
    package = pkgs.nixUnstable;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.11";

}
