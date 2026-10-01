{
  flake.modules.nixos.hydra =
    { config, lib, ... }:
    let
      postgresql = config.services.postgresql;
      asPostgres = "runuser -u ${postgresql.superUser} -- ${postgresql.package}/bin";
    in
    {
      nix = {
        buildMachines = [
          {
            hostName = "localhost";
            protocol = null;
            system = "x86_64-linux";
            supportedFeatures = [
              "kvm"
              "nixos-test"
              "big-parallel"
              "benchmark"
            ];
            maxJobs = 8;
          }
        ];
        settings.allowed-uris = [
          "github:"
          "git+https://github.com/"
          "git+ssh://github.com/"
        ];
      };

      services.hydra = {
        enable = true;
        hydraURL = "https://hydra.home.arpa.sne.moe";
        notificationSender = "hydra@nvirellia.im";
        useSubstitutes = true;
      };

      # Patch the upstream script after merging, preserving its other setup steps.
      # The pinned nixpkgs misses runuser's option separator and cannot retry a
      # partially completed database initialization.
      systemd.services.hydra-init = _: {
        options.preStart = lib.mkOption {
          apply =
            lib.replaceStrings
              [
                "runuser -u ${postgresql.superUser} ${postgresql.package}/bin/createuser hydra"
                "runuser -u ${postgresql.superUser} ${postgresql.package}/bin/createdb -O hydra hydra"
              ]
              [
                ''
                  hydra_role_exists=$(${asPostgres}/psql -XAt -v ON_ERROR_STOP=1 -d postgres -c "SELECT 1 FROM pg_roles WHERE rolname = 'hydra'")
                  if [ "$hydra_role_exists" != 1 ]; then
                    ${asPostgres}/createuser hydra
                  fi
                ''
                ''
                  hydra_database_exists=$(${asPostgres}/psql -XAt -v ON_ERROR_STOP=1 -d postgres -c "SELECT 1 FROM pg_database WHERE datname = 'hydra'")
                  if [ "$hydra_database_exists" != 1 ]; then
                    ${asPostgres}/createdb -O hydra hydra
                  fi
                ''
              ];
        };
      };
    };
}
