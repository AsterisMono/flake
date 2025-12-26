{
  lib,
  nixosModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.server
    diskLayouts.gpt-bios-compat-swap
  ];

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [ "--disable traefik" ];
  };

  services.postgresql =
    let
      databases = [ "pocketid" ];
    in
    {
      enable = true;
      settings = {
        listen_addresses = lib.mkOverride 10 "0.0.0.0";
      };
      ensureDatabases = databases;
      ensureUsers = builtins.map (name: {
        inherit name;
        ensureDBOwnership = true;
      }) databases;
      authentication = lib.mkOverride 10 ''
        #type  database  DBuser       address       auth-method
        local  all       all                        trust
        host   all       postgres     127.0.0.1/32  scram-sha-256
        host   sameuser  all          10.42.0.0/16  trust
        host   all       all          0.0.0.0/0     reject
      '';
    };

  networking.firewall = {
    allowedTCPPorts = [
      6443
    ];
    trustedInterfaces = [
      "cni0"
      "flannel.1"
    ];
  };

  disko.devices.disk.main.device = "/dev/sda";
}
