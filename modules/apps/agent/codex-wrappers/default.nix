{
  inputs,
  ...
}:
{
  # Codex talks to one provider per CODEX_HOME, so a wrapper is a command that
  # runs the upstream binary against a provider of its own: it points CODEX_HOME
  # at that provider's directory, exports the API key NixOS provisioned for it,
  # and leaves the rest to Codex. Home Manager's `programs.codex` owns Codex
  # itself, so the wrappers keep their own option namespace.
  flake.modules.homeManager.codex-wrappers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.codex-wrappers;
      tomlFormat = pkgs.formats.toml { };
      defaultPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

      wrapperType = lib.types.submodule (
        { name, ... }:
        {
          options = {
            enable = lib.mkEnableOption "the ${name} Codex wrapper";

            package = lib.mkOption {
              type = lib.types.package;
              default = defaultPackage;
              defaultText = lib.literalExpression "inputs.llm-agents.packages.\${pkgs.stdenv.hostPlatform.system}.codex";
              description = "The Codex package this wrapper runs.";
            };

            directory = lib.mkOption {
              type = lib.types.str;
              default = ".local/share/${name}";
              description = ''
                Directory below `$HOME` that becomes `CODEX_HOME` for this
                wrapper. Codex keeps its config.toml, sessions and caches there,
                which is what keeps wrappers from sharing provider state.
              '';
            };

            apiKeyEnvironmentVariable = lib.mkOption {
              type = lib.types.str;
              example = "DEEPSEEK_API_KEY";
              description = ''
                Environment variable the wrapper exports with the API key it
                reads from `apiKeyFile`.
              '';
            };

            apiKeyFile = lib.mkOption {
              type = lib.types.str;
              example = "/run/secrets/deepseek_api_key";
              description = ''
                Runtime file holding the API key, normally the path of a sops
                secret that NixOS provisioned for this user.
              '';
            };

            modelCatalog = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                Model catalog to install as `models.json` beside this wrapper's
                config.toml. It selects the models Codex may offer for this
                provider.
              '';
            };

            settings = lib.mkOption {
              inherit (tomlFormat) type;
              default = { };
              example = {
                model = "deepseek-flash";
                model_provider = "deepseek";
                model_reasoning_effort = "high";
              };
              description = ''
                Codex settings written to this wrapper's config.toml. See
                https://github.com/openai/codex for the accepted settings.
              '';
            };
          };
        }
      );

      codexHome = wrapper: "${config.home.homeDirectory}/${wrapper.directory}";

      codexExecutable = wrapper: lib.getExe wrapper.package;

      generatedConfig =
        name: wrapper:
        tomlFormat.generate "${name}-config.toml" (
          wrapper.settings
          // lib.optionalAttrs (wrapper.modelCatalog != null) {
            model_catalog_json = "${codexHome wrapper}/models.json";
          }
        );

      wrapperCommand =
        name: wrapper:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            export CODEX_HOME=${lib.escapeShellArg (codexHome wrapper)}
            ${wrapper.apiKeyEnvironmentVariable}="$(cat ${wrapper.apiKeyFile})"
            export ${wrapper.apiKeyEnvironmentVariable}

            exec ${codexExecutable wrapper} "$@"
          '';
        };

      # Codex persists trust levels, MCP servers, and TUI settings by rewriting
      # config.toml, which fails against the read-only symlink that home.file
      # creates. Keep a real copy instead: refresh it from the store while it is
      # still untouched, then leave local edits alone.
      installConfig =
        name: wrapper:
        let
          generated = generatedConfig name wrapper;
          configFile = "${codexHome wrapper}/config.toml";
          deployedFile = "${codexHome wrapper}/.config.toml.deployed";
        in
        lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
          if [ -L "${configFile}" ] || [ ! -e "${configFile}" ] \
            || ${lib.getExe' pkgs.coreutils "cmp"} -s "${configFile}" "${deployedFile}"; then
            $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -D -m 0644 "${generated}" "${configFile}"
          fi
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -D -m 0644 "${generated}" "${deployedFile}"
        '';

      wrappers = lib.filterAttrs (_: wrapper: wrapper.enable) cfg;
      catalogWrappers = lib.filterAttrs (_: wrapper: wrapper.modelCatalog != null) wrappers;
    in
    {
      options.programs.codex-wrappers = lib.mkOption {
        type = lib.types.attrsOf wrapperType;
        default = { };
        example = lib.literalExpression ''
          {
            csh = {
              enable = true;
              apiKeyEnvironmentVariable = "DEEPSEEK_API_KEY";
              apiKeyFile = config.constants.resources.userSecretPaths.deepseek_api_key;
            };
          }
        '';
        description = ''
          Codex wrappers, keyed by the command name they install. A wrapper runs
          Codex against a provider of its own: its own CODEX_HOME, its own
          config.toml, and its own API key.
        '';
      };

      config = {
        home.packages = lib.mapAttrsToList wrapperCommand wrappers;

        home.file = lib.listToAttrs (
          lib.mapAttrsToList (name: wrapper: {
            name = "${wrapper.directory}/models.json";
            value.source = wrapper.modelCatalog;
          }) catalogWrappers
        );

        home.activation = lib.mapAttrs' (
          name: wrapper: lib.nameValuePair "${name}Config" (installConfig name wrapper)
        ) wrappers;
      };
    };
}
