_:
{
  services.caddy = {
    enable = true;
    globalConfig = ''
      email cmiki@amono.me
    '';
    virtualHosts = {
      "citadel.requiem.garden".extraConfig = ''
        reverse_proxy 127.0.0.1:2283
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
