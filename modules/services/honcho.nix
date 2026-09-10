{
  flake.modules.nixos.honcho =
    { config, pkgs, ... }:
    let
      db = "honcho-db";
      redis = "honcho-redis";
      image = "ghcr.io/plastic-labs/honcho:latest";
      connectionEnvironment = {
        DB_CONNECTION_URI = "postgresql+psycopg://postgres:postgres@${db}:5432/postgres";
        CACHE_URL = "redis://${redis}:6379/0?suppress=true";
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
            ];
          };

          honcho-redis = {
            image = "redis:8.2";
            volumes = [ "honcho-redis-data:/data" ];
          };

          honcho-api = {
            inherit image;
            entrypoint = "sh";
            cmd = [ "docker/entrypoint.sh" ];
            dependsOn = [
              "honcho-db"
              "honcho-redis"
            ];
            ports = [ "127.0.0.1:8000:8000" ];
            environment = connectionEnvironment;
            environmentFiles = [ config.sops.secrets.honcho_env.path ];
          };

          honcho-deriver = {
            inherit image;
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
        };
      };
    };
}
