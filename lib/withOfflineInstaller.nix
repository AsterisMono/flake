{
  flake,
  nixosConfig,
  lib,
}:
let
  getInputDrvs =
    pkgs: flakeLock:
    lib.attrsets.mapAttrsToList (
      name: value:
      # Reuse flake inputs
      if builtins.hasAttr name flake.inputs then
        flake.inputs."${name}"
      else if name == "root" then
        flake
      else if value.locked.type == "github" then
        pkgs.fetchFromGitHub {
          inherit (value.locked) owner repo rev;
          hash = value.locked.narHash;
        }
      else if value.locked.type == "gitlab" then
        pkgs.fetchFromGitLab {
          inherit (value.locked) owner repo rev;
          domain = value.locked.host;
          hash = value.locked.narHash;
        }
      else
        pkgs.fetchgit {
          inherit (value.locked) url rev;
          hash = value.locked.narHash;
        }
    ) flakeLock.nodes;
  flakeLock = lib.importJSON "${flake}/flake.lock";
in
nixosConfig
// {
  offlineInstaller =
    (lib.nixosSystem {
      modules = [
        (
          { modulesPath, pkgs, ... }:
          {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

            nixpkgs.hostPlatform.system = "x86_64-linux";

            nix.settings = {
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
                "https://nix-community.cachix.org"
                "https://cache.garnix.io"
              ];
              trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
              ];
            };

            environment.defaultPackages = with pkgs; [
              nixos-anywhere
              just
              disko
              nh
            ];

            isoImage = {
              contents = [
                {
                  source = flake.outPath;
                  target = "/flake";
                }
              ];
              storeContents = [
                nixosConfig.config.system.build.toplevel
              ]
              ++ (getInputDrvs pkgs flakeLock);
              includeSystemBuildDependencies = false;
            };

            users.users.root = {
              isSystemUser = true;
              shell = pkgs.bashInteractive;
              initialHashedPassword = lib.mkForce "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
              openssh.authorizedKeys.keys = lib.mkForce [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOz0CMmkGSXv4H77rmrmvadltAlwAZeVimxGoUAfArs"
              ];
            };
          }
        )
      ];
    }).config.system.build.isoImage;
}
