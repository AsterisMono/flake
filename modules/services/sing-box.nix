{
  flake.modules.nixos.services-sing-box = { config, ... }: {
    sops.secrets = { inherit (config.secrets) sing-box-config; };
    services.sing-box.enable = true;
  };
}
