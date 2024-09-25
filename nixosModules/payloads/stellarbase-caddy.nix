_:
{
  services.caddy = {
    enable = true;
    virtualHosts = {
      "photos.amono.me".extraConfig = ''
        reverse_proxy 127.0.0.1:2283
      '';
    };
  };
}
