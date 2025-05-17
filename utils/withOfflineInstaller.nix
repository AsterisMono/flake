{
  flake,
  nixosConfig,
  lib,
}:
let
  getInputDrvs =
    pkgs: flakeLock:
    map (
      { name, value }:
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
      inherit (nixosConfig.config.nixpkgs) system;
      modules = [
        (
          { modulesPath, pkgs, ... }:
          {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

            environment.defaultPackages = with pkgs; [
              nixos-facter
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
              ] ++ (getInputDrvs pkgs flakeLock);
              includeSystemBuildDependencies = false;
            };

            users.users.root = {
              isSystemUser = true;
              shell = pkgs.bashInteractive;
              initialHashedPassword = lib.mkForce "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
              openssh.authorizedKeys.keys = lib.mkForce [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGPXhPWInP+CEc8wd+BWUiAqIAAIbF6rYuoZkt0QNiH"
              ];
            };
          }
        )
      ];
    }).config.system.build.isoImage;
}
