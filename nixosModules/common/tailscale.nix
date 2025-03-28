{
  lib,
  config,
  pkgs,
  secrets,
  ...
}:
{
  options = {
    amono.tailscale.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Auto register and enable tailscale";
    };
  };
  config = lib.mkIf config.amono.tailscale.enable {
    environment.systemPackages = [ pkgs.tailscale ];
    services.tailscale.enable = true;
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
      allowedTCPPorts = [ 22 ];
    };
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        secret=${secrets.tailscaleAuthKey}
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up -authkey $secret
      '';
    };
  };
}
