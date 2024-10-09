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

  # do garbage collection weekly to keep disk usage low
  nix = {
    gc.automatic = true;
    optimise.automatic = true;
  };

  services.nix-daemon.enable = true;

  # Optimise storage
  # you can also optimise the store manually via:
  #    nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;

  # Fvk Sequoia I'm not upgrading
  ids.uids.nixbld = 300;
}
