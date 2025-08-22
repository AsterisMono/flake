{
  inputs,
  pkgs,
  overlays,
  ...
}:
{
  nix = {
    package = pkgs.nixVersions.latest;
    registry = {
      noa.flake = inputs.self;
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
      ];
      extra-substituters = [
        "https://asterismono.cachix.org"
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "asterismono.cachix.org-1:GgkakezDphTbi2w+ksIkuk+LfIbD32IbsxrpmnDpPvo="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    inherit overlays;
  };

  # do garbage collection weekly to keep disk usage low
  nix = {
    gc.automatic = true;
    optimise.automatic = true;
  };
}
