{ inputs, ... }: {
  flake.modules.generic.resources = { lib, ... }: {
    options.constants.resources = lib.mkOption {
      type = with lib.types; attrsOf unspecified;
      default = { };
    };

    config.constants.resources = {
      getSecretPath = fileName: "${inputs.self}/modules/secrets/${fileName}";

      # Runtime paths of secrets that NixOS provisions for an unprivileged
      # consumer, so Home Manager can read the file without a key of its own.
      userSecretPaths = {
        deepseek_api_key = "/run/secrets/deepseek_api_key";
        opencode_api_key = "/run/secrets/opencode_api_key";
        openrouter_management_key = "/run/secrets/openrouter_management_key";
      };
    };
  };
}
