{
  config,
  pkgs,
  lib,
  inputs,
  overlays,
  system,
  ...
}:

{
  config = {
    nix = {
      package = pkgs.nix;
      channel.enable = false;
      registry = {
        noa.flake = inputs.self;
      };
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = lib.mkIf config.noa.nix.enableMirrorSubstituter [
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://mirrors.ustc.edu.cn/nix-channels/store"
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

      # Suppress nix-shell channel errors on a flake system
      nixPath = [ "/etc/nix/path" ];

      # do garbage collection weekly to keep disk usage low
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;

    nixpkgs = {
      hostPlatform = { inherit system; };
      config.allowUnfree = true;
      inherit overlays;
    };

    system.stateVersion = "24.05";
  };

  options = {
    noa.nix.enableMirrorSubstituter = lib.mkEnableOption "Enable mirror for cache.nixos.org";
  };
}
