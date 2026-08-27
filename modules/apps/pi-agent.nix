_: {
  flake.modules.homeManager.pi-agent =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.pi-agent;
      jsonFormat = pkgs.formats.json { };
      contentType = lib.types.either lib.types.lines lib.types.path;
      resourceType = lib.types.either (lib.types.attrsOf contentType) lib.types.path;
      isPathLike = lib.hm.strings.isPathLike;

      addSuffix =
        suffix: name:
        if lib.hasSuffix suffix name || (suffix == ".ts" && lib.hasSuffix ".js" name) then
          name
        else
          "${name}${suffix}";
      mkFile = content: if isPathLike content then { source = content; } else { text = content; };
      mkResourceEntry =
        subdir: suffix: name: content:
        let
          isDirectory = isPathLike content && lib.pathIsDirectory content;
          targetName = if isDirectory then name else addSuffix suffix name;
        in
        lib.nameValuePair "${cfg.configDir}/${subdir}/${targetName}" (
          mkFile content // lib.optionalAttrs isDirectory { recursive = true; }
        );
      mkResourceEntries =
        subdir: suffix: resources:
        if builtins.isAttrs resources then
          lib.mapAttrs' (mkResourceEntry subdir suffix) resources
        else
          {
            "${cfg.configDir}/${subdir}" = {
              source = resources;
              recursive = true;
            };
          };
      mkSkillEntry =
        name: content:
        if isPathLike content && lib.pathIsDirectory content then
          lib.nameValuePair "${cfg.configDir}/skills/${name}" {
            source = content;
            recursive = true;
          }
        else
          lib.nameValuePair "${cfg.configDir}/skills/${name}/SKILL.md" (mkFile content);
      skillEntries =
        if builtins.isAttrs cfg.skills then
          lib.mapAttrs' mkSkillEntry cfg.skills
        else
          {
            "${cfg.configDir}/skills" = {
              source = cfg.skills;
              recursive = true;
            };
          };
      mkPromptFile = fileName: content: {
        "${cfg.configDir}/${fileName}" = mkFile content;
      };
    in
    {
      options.programs.pi-agent = {
        enable = lib.mkEnableOption "Pi coding agent";

        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = pkgs.llm-agents.pi;
          defaultText = lib.literalExpression "pkgs.llm-agents.pi";
          description = "The Pi package to install. Set to null to manage configuration only.";
        };

        configDir = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.pi/agent";
          defaultText = lib.literalExpression ''"\${config.home.homeDirectory}/.pi/agent"'';
          description = ''
            Directory containing Pi's global configuration. When changed from
            the upstream default, PI_CODING_AGENT_DIR is set accordingly.
          '';
        };

        settings = lib.mkOption {
          inherit (jsonFormat) type;
          default = { };
          example = {
            defaultProvider = "anthropic";
            defaultModel = "claude-sonnet-4-20250514";
            defaultThinkingLevel = "medium";
            enableInstallTelemetry = false;
          };
          description = ''
            Global Pi settings written to settings.json. See
            https://pi.dev/docs/settings for supported values. API keys should
            be supplied through environment variables, commands, or /login,
            rather than stored here.
          '';
        };

        keybindings = lib.mkOption {
          inherit (jsonFormat) type;
          default = { };
          example = {
            "tui.editor.historyPrevious" = "ctrl+p";
            "tui.editor.historyNext" = "ctrl+n";
          };
          description = "Pi keybindings written to keybindings.json.";
        };

        models = lib.mkOption {
          inherit (jsonFormat) type;
          default = { };
          example.providers.ollama = {
            baseUrl = "http://localhost:11434/v1";
            api = "openai-completions";
            apiKey = "ollama";
            models = [ { id = "qwen2.5-coder:7b"; } ];
          };
          description = ''
            Custom providers and models written to models.json. Reference
            secrets through environment variables or commands instead of
            embedding them in the Nix store.
          '';
        };

        context = lib.mkOption {
          type = contentType;
          default = "";
          description = ''
            Global agent instructions, supplied as inline text or a file path,
            and written to AGENTS.md.
          '';
        };

        systemPrompt = lib.mkOption {
          type = contentType;
          default = "";
          description = ''
            Global replacement system prompt, supplied as inline text or a file
            path, and written to SYSTEM.md.
          '';
        };

        appendSystemPrompt = lib.mkOption {
          type = contentType;
          default = "";
          description = ''
            Global system prompt addition, supplied as inline text or a file
            path, and written to APPEND_SYSTEM.md.
          '';
        };

        extensions = lib.mkOption {
          type = resourceType;
          default = { };
          description = ''
            Global Pi extensions. Use an attribute set of inline TypeScript or
            file/directory paths, or a path containing extensions. Attribute
            names receive a .ts suffix unless they already end in .ts or .js.
          '';
        };

        prompts = lib.mkOption {
          type = resourceType;
          default = { };
          description = ''
            Global prompt templates. Use an attribute set of inline Markdown or
            file paths, or a directory path. Attribute names receive a .md
            suffix unless they already end in .md.
          '';
        };

        skills = lib.mkOption {
          type = resourceType;
          default = { };
          description = ''
            Global agent skills. Attribute values may be inline SKILL.md
            content, SKILL.md paths, or skill directory paths. A directory path
            may instead contain all skills.
          '';
        };

        themes = lib.mkOption {
          type = resourceType;
          default = { };
          description = ''
            Global Pi themes. Use an attribute set of inline JSON or file paths,
            or a directory path. Attribute names receive a .json suffix unless
            they already end in .json.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = !isPathLike cfg.extensions || lib.pathIsDirectory cfg.extensions;
            message = "`programs.pi-agent.extensions` must be a directory when set to a path";
          }
          {
            assertion = !isPathLike cfg.prompts || lib.pathIsDirectory cfg.prompts;
            message = "`programs.pi-agent.prompts` must be a directory when set to a path";
          }
          {
            assertion = !isPathLike cfg.skills || lib.pathIsDirectory cfg.skills;
            message = "`programs.pi-agent.skills` must be a directory when set to a path";
          }
          {
            assertion = !isPathLike cfg.themes || lib.pathIsDirectory cfg.themes;
            message = "`programs.pi-agent.themes` must be a directory when set to a path";
          }
          {
            assertion =
              !builtins.isAttrs cfg.prompts
              || lib.all (content: !(isPathLike content && lib.pathIsDirectory content)) (
                lib.attrValues cfg.prompts
              );
            message = "`programs.pi-agent.prompts` attribute values must be files when set to paths";
          }
          {
            assertion =
              !builtins.isAttrs cfg.themes
              || lib.all (content: !(isPathLike content && lib.pathIsDirectory content)) (
                lib.attrValues cfg.themes
              );
            message = "`programs.pi-agent.themes` attribute values must be files when set to paths";
          }
        ];

        home = {
          packages = lib.mkIf (cfg.package != null) [ cfg.package ];

          sessionVariables = lib.mkIf (cfg.configDir != "${config.home.homeDirectory}/.pi/agent") {
            PI_CODING_AGENT_DIR = cfg.configDir;
          };

          file = lib.mkMerge [
            (lib.mkIf (cfg.settings != { }) {
              "${cfg.configDir}/settings.json".source = jsonFormat.generate "pi-settings.json" cfg.settings;
            })
            (lib.mkIf (cfg.keybindings != { }) {
              "${cfg.configDir}/keybindings.json".source =
                jsonFormat.generate "pi-keybindings.json" cfg.keybindings;
            })
            (lib.mkIf (cfg.models != { }) {
              "${cfg.configDir}/models.json".source = jsonFormat.generate "pi-models.json" cfg.models;
            })
            (lib.mkIf (cfg.context != "") (mkPromptFile "AGENTS.md" cfg.context))
            (lib.mkIf (cfg.systemPrompt != "") (mkPromptFile "SYSTEM.md" cfg.systemPrompt))
            (lib.mkIf (cfg.appendSystemPrompt != "") (mkPromptFile "APPEND_SYSTEM.md" cfg.appendSystemPrompt))
            (lib.mkIf (cfg.extensions != { }) (mkResourceEntries "extensions" ".ts" cfg.extensions))
            (lib.mkIf (cfg.prompts != { }) (mkResourceEntries "prompts" ".md" cfg.prompts))
            (lib.mkIf (cfg.skills != { }) skillEntries)
            (lib.mkIf (cfg.themes != { }) (mkResourceEntries "themes" ".json" cfg.themes))
          ];
        };
      };
    };
}
