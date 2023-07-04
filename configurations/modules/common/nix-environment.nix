{ pkgs, ... }:

{

  nix = {
    package = pkgs.nixUnstable;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
      extra-substituters = [ "https://asterismono.cachix.org" ];
      trusted-public-keys = [
        "asterismono.cachix.org-1:GgkakezDphTbi2w+ksIkuk+LfIbD32IbsxrpmnDpPvo="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.11";

}
