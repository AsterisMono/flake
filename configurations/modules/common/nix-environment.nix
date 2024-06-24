{ pkgs, ... }:

{

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
      extra-substituters = [
        "https://asterismono.cachix.org"
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "asterismono.cachix.org-1:GgkakezDphTbi2w+ksIkuk+LfIbD32IbsxrpmnDpPvo="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
      trusted-users = [
        "cmiki"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";

}
