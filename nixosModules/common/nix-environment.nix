{
  flake,
  config,
  pkgs,
  lib,
  ...
}:

{
  nix = {
    package = pkgs.nixVersions.latest;
    channel.enable = false;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # If proxy is enabled, use mirror to speed up nix binary cache
      substituters = lib.optionals config.amono.proxy.enable [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
      ];
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://asterismono.cachix.org"
        "https://devenv.cachix.org"
        "https://cosmic.cachix.org"
      ];
      trusted-public-keys = [
        "asterismono.cachix.org-1:GgkakezDphTbi2w+ksIkuk+LfIbD32IbsxrpmnDpPvo="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [
        "cmiki"
      ];
    };
    # Suppress nix-shell channel errors on a flake system
    nixPath = [ "/etc/nix/path" ];
  };

  environment.etc."nix/path/nixpkgs".source = flake.inputs.nixpkgs;

  nixpkgs.config.allowUnfree = true;

  # do not need to keep too much generations
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  system.stateVersion = "24.05";
}
