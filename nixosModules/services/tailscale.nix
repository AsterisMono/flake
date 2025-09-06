{
  lib,
  pkgs,
  config,
  secretsPath,
  ...
}:
{
  options.noa.tailscale = {
    ssh.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.services.openssh.enable;
      description = "Enable tailscale SSH";
    };
    advertiseTags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Tags to advertise";
    };
    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Routes to advertise";
    };
    pickupRoutes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable subnet routes";
    };
    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra flags to pass to tailscale up";
    };
  };

  config = {
    sops.secrets.ts_authkey = {
      format = "yaml";
      sopsFile = "${secretsPath}/tailscale.yaml";
      restartUnits = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
    };

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.ts_authkey.path;
      extraUpFlags =
        config.noa.tailscale.extraUpFlags
        ++ lib.optionals (config.noa.tailscale.advertiseRoutes != [ ]) [
          "--advertise-routes=${lib.strings.concatStringsSep "," config.noa.tailscale.advertiseRoutes}"
        ]
        ++ [
          "--advertise-tags=tag:nixos${
            lib.optionalString (
              config.noa.tailscale.advertiseTags != [ ]
            ) ",${lib.strings.concatStringsSep "," config.noa.tailscale.advertiseTags}"
          }"
        ]
        ++ lib.optionals config.noa.tailscale.ssh.enable [
          "--ssh"
        ]
        ++ lib.optionals config.noa.tailscale.pickupRoutes [
          "--accept-routes"
        ];
      useRoutingFeatures = if config.noa.tailscale.advertiseRoutes != [ ] then "both" else "client";
    };

    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    boot.kernelPatches = [
      # Fix the /proc/net/tcp seek issue
      # Impacts tailscale: https://github.com/tailscale/tailscale/issues/16966
      {
        name = "proc: fix missing pde_set_flags() for net proc files";
        patch = pkgs.fetchurl {
          name = "fix-missing-pde_set_flags-for-net-proc-files.patch";
          url = "https://patchwork.kernel.org/project/linux-fsdevel/patch/20250821105806.1453833-1-wangzijie1@honor.com/raw/";
          hash = "sha256-DbQ8FiRj65B28zP0xxg6LvW5ocEH8AHOqaRbYZOTDXg=";
        };
      }
    ];

  };
}
