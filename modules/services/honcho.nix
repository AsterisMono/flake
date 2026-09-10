{
  flake.modules.nixos.honcho =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      image = "ghcr.io/plastic-labs/honcho:latest";
      # Host networking: podman's internal DNS is unreliable here (sing-box
      # intercepts UDP/53), so every service binds 127.0.0.1 on the host and
      # they talk to each other over loopback.
      connectionEnvironment = {
        DB_CONNECTION_URI = "postgresql+psycopg://postgres:postgres@127.0.0.1:5432/postgres";
        CACHE_URL = "redis://127.0.0.1:6379/0?suppress=true";
        CACHE_ENABLED = "true";
        AUTH_USE_AUTH = "false";
        VECTOR_STORE_TYPE = "pgvector";
      };
    in
    {
      sops.secrets.honcho_env = {
        format = "dotenv";
        key = "";
        sopsFile = config.constants.resources.getSecretPath "honcho.env";
        restartUnits = [
          "podman-honcho-api.service"
          "podman-honcho-deriver.service"
        ];
      };

      virtualisation.oci-containers = {
        backend = "podman";
        containers = {
          honcho-db = {
            image = "pgvector/pgvector:pg15";
            extraOptions = [ "--network=host" ];
            environment = {
              POSTGRES_DB = "postgres";
              POSTGRES_USER = "postgres";
              POSTGRES_PASSWORD = "postgres";
              POSTGRES_HOST_AUTH_METHOD = "trust";
              PGDATA = "/var/lib/postgresql/data/pgdata";
            };
            volumes = [
              "honcho-pgdata:/var/lib/postgresql/data"
              "${pkgs.writeText "honcho-init.sql" "CREATE EXTENSION IF NOT EXISTS vector;\n"}:/docker-entrypoint-initdb.d/init.sql:ro"
            ];
            cmd = [
              "postgres"
              "-c"
              "max_connections=200"
              "-c"
              "listen_addresses=127.0.0.1"
            ];
          };

          honcho-redis = {
            image = "redis:8.2";
            extraOptions = [ "--network=host" ];
            volumes = [ "honcho-redis-data:/data" ];
            cmd = [
              "redis-server"
              "--bind"
              "127.0.0.1"
            ];
          };

          honcho-api = {
            inherit image;
            extraOptions = [ "--network=host" ];
            entrypoint = "sh";
            cmd = [
              "-c"
              "/app/.venv/bin/python scripts/provision_db.py && exec /app/.venv/bin/fastapi run --host 127.0.0.1 --workers 1 src/main.py"
            ];
            dependsOn = [
              "honcho-db"
              "honcho-redis"
            ];
            environment = connectionEnvironment;
            environmentFiles = [ config.sops.secrets.honcho_env.path ];
          };

          honcho-deriver = {
            inherit image;
            extraOptions = [ "--network=host" ];
            entrypoint = "/app/.venv/bin/python";
            cmd = [
              "-m"
              "src.deriver"
            ];
            dependsOn = [
              "honcho-db"
              "honcho-redis"
              "honcho-api"
            ];
            environment = connectionEnvironment;
            environmentFiles = [ config.sops.secrets.honcho_env.path ];
          };
        };
      };

      systemd.services = {
        "podman-honcho-api" = {
          after = [ "sops-install-secrets.service" ];
          requires = [ "sops-install-secrets.service" ];
        };
        "podman-honcho-deriver" = {
          after = [ "sops-install-secrets.service" ];
          requires = [ "sops-install-secrets.service" ];
          # The deriver validates the embedding schema at startup and exits 0
          # when the API's migrations have not finished yet, so keep restarting
          # it until the schema is ready.
          serviceConfig = {
            Restart = lib.mkForce "always";
            RestartSec = 10;
          };
        };
      };
    };
}
