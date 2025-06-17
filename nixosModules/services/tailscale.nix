{
  lib,
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
  };
}
