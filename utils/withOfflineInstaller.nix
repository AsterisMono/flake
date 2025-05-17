{
  flake,
  nixosConfig,
  lib,
}:
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

            isoImage =
              let
                offlineFlake = flake.lib.mkOfflineFlake { inherit flake pkgs; };
              in
              {
                contents = [
                  {
                    source = flake.outPath;
                    target = "/flake";
                  }
                  {
                    source = pkgs.writeTextFile {
                      name = "overrideFlags";
                      text = offlineFlake.overrideFlags;
                    };
                    target = "/overrideFlags";
                  }
                ];
                storeContents = [
                  nixosConfig.config.system.build.toplevel
                ] ++ offlineFlake.collectedInputDrvs;
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
