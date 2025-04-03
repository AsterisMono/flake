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
      extraUpFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra flags to pass to tailscale up";
      };
    };
  };
  config = lib.mkIf config.amono.tailscale.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = secrets.tailscaleAuthKey;
      extraUpFlags =
        config.amono.tailscale.extraUpFlags
        ++ lib.optionals (config.amono.tailscale.advertiseRoutes != [ ]) [
          "--advertise-routes=${lib.strings.concatStringsSep "," config.amono.tailscale.advertiseRoutes}"
        ]
        ++ lib.optionals (config.amono.tailscale.advertiseTags != [ ]) [
          "--advertise-tags=${lib.strings.concatStringsSep "," config.amono.tailscale.advertiseTags}"
        ]
        ++ lib.optionals config.amono.tailscale.ssh.enable [
          "--ssh"
        ];
      useRoutingFeatures = if config.amono.tailscale.advertiseRoutes != [ ] then "both" else "client";
    };
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
}
