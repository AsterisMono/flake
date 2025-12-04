{
  config,
  pkgs,
  lib,
  inputs,
  nixosModules,
  secretsPath,
  ...
}:
let
  headscale_url = "tether.requiem.garden";
in
{
  # Anemone (JP.TKY.TRI.Core)

  imports = with nixosModules; [
    inputs.headplane.nixosModules.headplane
    roles.server
    diskLayouts.gpt-bios-compat
  ];

  nixpkgs.overlays = [
    inputs.headplane.overlays.default
  ];

  services.headscale = {
    enable = true;
    settings = {
      server_url = "https://${headscale_url}";
      dns = {
        magic_dns = true;
        base_domain = "paths.requiem.garden";
        override_local_dns = false;
      };
    };
    address = "0.0.0.0";
    port = 40180;
  };

  sops.secrets.headplane_cookie_secret = {
    format = "yaml";
    sopsFile = "${secretsPath}/headscale.yaml";
    owner = config.services.headscale.user;
  };

  services.headplane =
    let
      format = pkgs.formats.yaml { };

      # A workaround generate a valid Headscale config accepted by Headplane when `config_strict == true`.
      settings = lib.recursiveUpdate config.services.headscale.settings {
        tls_cert_path = "/dev/null";
        tls_key_path = "/dev/null";
        policy.path = "/dev/null";
        # FIXME: upstream
        oidc.client_secret_path = "/dev/null";
      };

      headscaleConfig = format.generate "headscale.yml" settings;
    in
    {
      enable = true;
      settings = {
        server = {
          host = "127.0.0.1";
          port = 3000;
          cookie_secret_path = config.sops.secrets.headplane_cookie_secret.path;
        };
        headscale = {
          public_url = "https://${headscale_url}";
          url = "http://127.0.0.1:40180";
          config_path = "${headscaleConfig}";
        };
        integration = {
          agent = {
            # FIXME: upstream module
            pre_authkey_path = "/dev/null";
          };
        };
      };
    };

  services.caddy = {
    enable = true;
    extraConfig = ''
      ${headscale_url} {
        @admin path /admin/*
        handle @admin {
          reverse_proxy localhost:3000
        }
        handle {
          reverse_proxy localhost:40180
        }
      }
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      3478
    ];
  };

  disko.devices.disk.main.device = "/dev/vda";
}
