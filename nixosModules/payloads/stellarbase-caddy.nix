_:
{
  services.caddy = {
    enable = true;
    globalConfig = ''
      email cmiki@amono.me
    '';
    virtualHosts = {
      "photos.amono.me".extraConfig = ''
        reverse_proxy 127.0.0.1:2283
      '';
      "neko.amono.me".extraConfig = ''
        reverse_proxy 127.0.0.1:8340
      '';
      "whisper.amono.me".extraConfig = ''
        reverse_proxy 127.0.0.1:6777
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
