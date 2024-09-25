_:
{
  services.syncthing = {
    enable = true;
    user = "cmiki";
    dataDir = "/home/cmiki/Sync";
    configDir = "/home/cmiki/.config/syncthing";
  };
  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
