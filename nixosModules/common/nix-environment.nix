{
  config,
  inputs,
  pkgs,
  lib,
  overlays,
  ...
}:

{
  config = {
    nix = {
      package = pkgs.nixVersions.latest;
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
          "https://asterismono.cachix.org"
        ];
        trusted-public-keys = [
          "asterismono.cachix.org-1:GgkakezDphTbi2w+ksIkuk+LfIbD32IbsxrpmnDpPvo="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      # Suppress nix-shell channel errors on a flake system
      nixPath = [ "/etc/nix/path" ];

      # do garbage collection weekly to keep disk usage low
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 1w";
      };
    };

    environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;

    nixpkgs = {
      config.allowUnfree = true;
      overlays = [
        overlays.flake-packages
      ];
    };

    system.stateVersion = "24.05";
  };

  options = {
    noa.nix.enableMirrorSubstituter = lib.mkEnableOption "Enable mirror for cache.nixos.org";
  };
}
