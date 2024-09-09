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
        "https://cosmic.cachix.org"
      ];
      trusted-public-keys = [
        "asterismono.cachix.org-1:GgkakezDphTbi2w+ksIkuk+LfIbD32IbsxrpmnDpPvo="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];
      trusted-users = [
        "cmiki"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  # do not need to keep too much generations
  boot.loader.systemd-boot.configurationLimit = 10;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  # Optimise storage
  # you can also optimise the store manually via:
  #    nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "24.05";
}
