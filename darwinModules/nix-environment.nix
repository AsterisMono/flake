{
  inputs,
  pkgs,
  overlays,
  system,
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
        "https://mirrors4.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://ipv4.mirrors.ustc.edu.cn/nix-channels/store"
      ];
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
  };

  nixpkgs = {
    hostPlatform = { inherit system; };
    config.allowUnfree = true;
    inherit overlays;
  };

  # do garbage collection weekly to keep disk usage low
  nix = {
    gc.automatic = true;
    optimise.automatic = true;
  };
}
