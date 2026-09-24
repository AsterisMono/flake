{
  flake.modules.homeManager.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.herdr.projects;

      # Herdr's own default sidebar rows. A `rows` array replaces them
      # wholesale, so the rows `herdr-projects configure` appends have to
      # repeat them. Taken from `herdr --default-config`.
      defaultAgentRows = [
        [
          "state_icon"
          "machine"
          "workspace"
          "tab"
        ]
        [ "agent" ]
      ];
      defaultSpaceRows = [
        [
          "state_icon"
          "workspace"
        ]
        [
          "branch"
          "git_status"
        ]
      ];

      # What `herdr-projects configure` puts in `~/.config/herdr/config.toml`:
      # the state line and self-report per agent, the project count per Space,
      # a popup key, and a tab-bar count. Each sidebar row is its own array,
      # like Herdr's built-in rows.
      projectsAgentRows = [
        [
          {
            token = "$hp_state";
            rules = [
              {
                starts_with = "needs you";
                fg = "#f38ba8";
                bold = true;
              }
              {
                starts_with = "review";
                fg = "#f9e2af";
              }
            ];
          }
        ]
        [
          {
            token = "$hp_activity";
            dim = true;
          }
        ]
      ];
      projectsSpaceRows = [
        [ { token = "$hp"; } ]
      ];
      # Absolute paths and quoting: the tab bar runs this under `/bin/sh -lc`
      # on the Herdr server, without the plugin environment.
      projectsTabCommand = "${lib.escapeShellArg (lib.getExe cfg.package)} --root ${lib.escapeShellArg cfg.root} needs-you --line";

      contributesSettings =
        settings:
        let
          agents = settings.ui.sidebar.agents or { };
          spaces = settings.ui.sidebar.spaces or { };
          # A per-agent row override replaces the default rows, so ours have to
          # be repeated in each one, as `configure` does.
          rowsByAgent = lib.mapAttrs (_: rows: rows ++ projectsAgentRows) (agents.rows_by_agent or { });
        in
        {
          keys.command = (settings.keys.command or [ ]) ++ [
            {
              inherit (cfg) key;
              type = "plugin_action";
              command = "herdr-projects.open-popup";
              description = "Projects";
            }
          ];
          ui = {
            tab_bar_right = (settings.ui.tab_bar_right or [ ]) ++ [
              {
                type = "command";
                command = projectsTabCommand;
                interval_seconds = 15;
                timeout_seconds = 5;
              }
            ];
            sidebar = {
              agents = {
                rows = (agents.rows or defaultAgentRows) ++ projectsAgentRows;
              }
              // lib.optionalAttrs (rowsByAgent != { }) {
                rows_by_agent = rowsByAgent;
              };
              spaces.rows = (spaces.rows or defaultSpaceRows) ++ projectsSpaceRows;
            };
          };
        };
    in
    {
      options.programs.herdr.projects = {
        enable = lib.mkEnableOption ''
          the Herdr Projects sidebar rows, popup key and tab-bar count, as
          `herdr-projects configure` would add them to Herdr's config
        '';

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.selfPackages.herdr-projects;
          defaultText = lib.literalExpression "pkgs.selfPackages.herdr-projects";
          description = ''
            The Herdr Projects package. Its binary is invoked by the tab-bar
            entry and installs the progress hooks, so it must match the plugin
            the running Herdr links.
          '';
        };

        root = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.herdr-projects";
          defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.herdr-projects"'';
          example = "/home/me/.herdr-projects";
          description = ''
            The projects root the tab-bar entry and the progress hooks read.
            Must match the root the plugin's `[[startup]]` command runs with,
            which is $HERDR_PROJECTS_ROOT or the plugin's own default.
          '';
        };

        key = lib.mkOption {
          type = lib.types.str;
          default = "prefix+a";
          description = ''
            The key that opens the projects popup
            (`herdr-projects.open-popup`). Herdr refuses a key that is
            already bound, so changing this needs a free key.
          '';
        };

        # The progress hooks are separate from the rest: they edit Claude
        # Code's and Codex's own files, not Herdr's. Turning this back off
        # leaves the hooks behind; `herdr-projects unconfigure` removes them.
        hooks = {
          enable = lib.mkEnableOption ''
            the progress self-report hooks `herdr-projects configure`
            installs into Claude Code and Codex
          '';

          clients = lib.mkOption {
            type = lib.types.listOf (
              lib.types.enum [
                "claude"
                "codex"
              ]
            );
            default = [ ];
            example = [ "codex" ];
            description = ''
              The harnesses whose hooks to install. Empty installs them for
              every harness whose config directory exists, like
              `herdr-projects configure` does on its own. Hooks go to the
              harnesses' default homes ($HOME/.claude and $HOME/.codex).
            '';
          };
        };
      };

      config = lib.mkIf cfg.enable {
        programs.herdr.plugins.herdr-projects = cfg.package;

        programs.herdr.pluginSettings = [ contributesSettings ];

        # The hooks live in files Claude Code and Codex rewrite themselves, so
        # they stay real files the plugin merges into rather than home-manager
        # symlinks. `configure --hooks-only` is idempotent and records what it
        # added, which is what `herdr-projects unconfigure` removes.
        #
        # The harness homes are cleared so the hooks land where the harnesses
        # Herdr starts read them, rather than where a wrapper (`csh`) or an
        # outer session left CODEX_HOME or CLAUDE_CONFIG_DIR pointing.
        home.activation.installHerdrProjectsHooks = lib.mkIf cfg.hooks.enable (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if ! $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "env"} -u CODEX_HOME -u CLAUDE_CONFIG_DIR ${lib.getExe cfg.package} --root ${lib.escapeShellArg cfg.root} configure --hooks-only${
              lib.optionalString (
                cfg.hooks.clients != [ ]
              ) " --clients ${lib.concatStringsSep "," cfg.hooks.clients}"
            }; then
              echo "herdr-projects: could not install the progress hooks; run \`herdr-projects configure --hooks-only --dry-run\` to see why" >&2
            fi
          ''
        );
      };
    };
}
