{
  lib,
  config,
  secrets,
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
    isEphemeral = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Is this machine ephemeral";
    };
  };

  config = {
    services.tailscale = {
      enable = true;
      authKeyFile =
        if config.noa.tailscale.isEphemeral then
          secrets.tailscaleKeys.ephemeral
        else
          secrets.tailscaleKeys.reusable;
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
