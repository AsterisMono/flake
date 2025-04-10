{
  lib,
  config,
  secrets,
  ...
}:
{
  options = {
    amono.tailscale = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Auto register and enable tailscale";
      };
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
  };
  config = lib.mkIf config.amono.tailscale.enable {
    services.tailscale = {
      enable = true;
      authKeyFile =
        if config.amono.tailscale.isEphemeral then
          secrets.tailscaleKeys.ephemeral
        else
          secrets.tailscaleKeys.reusable;
      extraUpFlags =
        config.amono.tailscale.extraUpFlags
        ++ lib.optionals (config.amono.tailscale.advertiseRoutes != [ ]) [
          "--advertise-routes=${lib.strings.concatStringsSep "," config.amono.tailscale.advertiseRoutes}"
        ]
        ++ [
          "--advertise-tags=tag:nixos${
            lib.optionalString (
              config.amono.tailscale.advertiseTags != [ ]
            ) ",${lib.strings.concatStringsSep "," config.amono.tailscale.advertiseTags}"
          }"
        ]
        ++ lib.optionals config.amono.tailscale.ssh.enable [
          "--ssh"
        ]
        ++ lib.optionals config.amono.tailscale.pickupRoutes [
          "--accept-routes"
        ];
      useRoutingFeatures = if config.amono.tailscale.advertiseRoutes != [ ] then "both" else "client";
    };
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
}
