{ inputs, ... }: {
  flake-file.inputs.catppuccin-zed = {
    url = "github:catppuccin/zed";
    flake = false;
  };

  flake.modules.homeManager.zed =
    { pkgs, lib, ... }:
    let
      typescriptSettings = {
        code_actions_on_format = {
          "source.addMissingImports.ts" = true;
          "source.fixAll.eslint" = true;
          "source.fixAll.ts" = true;
          "source.removeUnusedImports.ts" = true;
        };
        language_servers = [
          "typescript-language-server"
          "!vtsls"
          "..."
        ];
      };

      catppuccin = builtins.fromJSON (
        builtins.readFile (inputs.catppuccin-zed + "/themes/catppuccin-mauve.json")
      );

      # The glass this desktop already had, as the alpha each Zed style key
      # carries. These are the effective values of the theme this replaces, not
      # the ones it declares: Zed draws drop shadows and fade gradients over a
      # surface assuming it has an opaque base, so the `40` entries below keep
      # the faint tint that hides those artifacts instead of going fully
      # transparent. Everything else is unchanged, so only the palette moves:
      # the window and the two bars keep a translucent base, the editor and the
      # panels take that tint, and the interactive tints stay where they were
      # tuned. Every key here exists in the Catppuccin theme.
      glassAlpha = {
        background = "cf";
        border = "66";
        "border.disabled" = "3d";
        "border.transparent" = "3d";
        "border.variant" = "66";
        conflict = "99";
        created = "99";
        deleted = "99";
        "drop_target.background" = "99";
        "editor.active_line.background" = "0f";
        "editor.active_line_number" = "8f";
        "editor.active_wrap_guide" = "80";
        "editor.background" = "40";
        "editor.document_highlight.read_background" = "66";
        "editor.document_highlight.write_background" = "66";
        "editor.gutter.background" = "40";
        "editor.highlighted_line.background" = "40";
        "editor.invisible" = "00";
        "editor.line_number" = "2e";
        "editor.subheader.background" = "40";
        "editor.wrap_guide" = "66";
        "element.active" = "66";
        "element.background" = "66";
        "element.hover" = "66";
        "element.selected" = "c2";
        "elevated_surface.background" = "61";
        "error.background" = "9e";
        "ghost_element.hover" = "33";
        "ghost_element.selected" = "66";
        hidden = "66";
        "hint.background" = "9e";
        ignored = "66";
        "info.background" = "9e";
        modified = "99";
        "pane.focused_border" = "00";
        "panel.background" = "40";
        "panel.focused_border" = "00";
        "scrollbar.thumb.background" = "99";
        "scrollbar.thumb.hover_background" = "aa";
        "scrollbar.track.border" = "66";
        "search.match_background" = "33";
        "status_bar.background" = "cf";
        "surface.background" = "40";
        "tab.active_background" = "55";
        "tab.inactive_background" = "00";
        "tab_bar.background" = "0f";
        "terminal.background" = "40";
        "text.disabled" = "33";
        "text.muted" = "cc";
        "text.placeholder" = "66";
        "title_bar.background" = "cf";
        "toolbar.background" = "40";
        "warning.background" = "9e";
      };

      glassTheme =
        theme:
        let
          # The window's own base colour, standing in for the surfaces the port
          # leaves undefined so that they can still carry a tint.
          base = builtins.substring 0 7 theme.style.background;

          glassify =
            name: value:
            if !(builtins.hasAttr name glassAlpha) then
              value
            else
              let
                alpha = glassAlpha.${name};
                rgb =
                  if value == null then
                    base
                  else if lib.isString value && builtins.match "#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?" value != null then
                    builtins.substring 0 7 value
                  else
                    null;
              in
              if rgb == null then value else "${rgb}${alpha}";
        in
        theme
        // {
          style = builtins.mapAttrs glassify theme.style // {
            "background.appearance" = "blurred";
          };
        };

      glassyTheme = catppuccin // {
        themes = map glassTheme catppuccin.themes;
      };
    in
    {
      programs.zed-editor = {
        enable = true;
        package = pkgs.unstable.zed-editor;

        extensions = [
          "astro"
          "html"
          "just"
          "nix"
          "svelte"
          "nvim-nightfox"
          "biome"
          "terraform"
        ];

        themes.catppuccin = builtins.toJSON glassyTheme;

        userSettings = {
          agent_servers = {
            qwen-code.type = "registry";
            codex-acp = {
              default_config_options = {
                mode = "agent";
                reasoning_effort = "high";
              };
              type = "registry";
            };
          };

          agent = {
            tool_permissions.tools.terminal.default = "allow";
            default_model = {
              provider = "openrouter";
              model = "anthropic/claude-fable-5";
              enable_thinking = true;
            };
            dock = "right";
            favorite_models = [ ];
            model_parameters = [ ];
          };

          indent_guides = {
            enabled = true;
            coloring = "indent_aware";
          };
          cli_default_open_behavior = "new_window";
          buffer_font_family = "FiraCode Nerd Font";
          # Use static CJK fonts; non-400 weights can break Linux fallbacks.
          # https://github.com/zed-industries/zed/issues/60155
          buffer_font_fallbacks = [ "Source Han Sans SC" ];
          buffer_font_size = 15.0;
          buffer_font_weight = 400;
          ui_font_size = 16.0;
          ui_font_fallbacks = [ "Source Han Sans SC" ];
          ui_font_weight = 400;
          colorize_brackets = true;
          cursor_blink = false;
          diagnostics.inline.enabled = true;
          soft_wrap = "editor_width";
          git.inline_blame.enabled = false;

          languages = {
            JavaScript = typescriptSettings;
            Nix = {
              format_on_save = "on";
              formatter.external.command = "nixfmt";
              language_servers = [
                "nixd"
                "!nil"
                "..."
              ];
            };
            TSX = typescriptSettings;
            TypeScript = typescriptSettings;
          };

          load_direnv = "direct";
          lsp = {
            json-language-server.settings.json.schemas = [
              {
                fileMatch = [ "package.json" ];
                url = "https://www.schemastore.org/package";
              }
            ];
            yaml-language-server.settings.yaml = {
              schemaStore.enable = true;
              completion = true;
            };
            biome.settings.require_config_file = true;
          };

          project_panel.dock = "left";
          rounded_selection = false;
          status_bar = {
            active_language_button = false;
            cursor_position_button = false;
          };
          tab_bar = {
            show_nav_history_buttons = false;
            show_tab_bar_buttons = false;
          };
          tabs = {
            git_status = true;
            show_diagnostics = "errors";
          };
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          terminal = {
            blinking = "off";
            cursor_shape = "bar";
            shell.program = lib.getExe pkgs.fish;
            scrollbar.show = "never";
          };
          theme = {
            dark = "Catppuccin Mocha";
            light = "Catppuccin Latte";
            mode = "dark";
          };
          title_bar.show_user_picture = false;
          toolbar.quick_actions = false;
          ui_font_family = "FiraCode Nerd Font";
          vim.use_system_clipboard = "on_yank";
          vim_mode = true;
          which_key.enabled = true;
        };

        userKeymaps = [
          {
            context = "Dock";
            bindings = {
              "ctrl-w h" = "workspace::ActivatePaneLeft";
              "ctrl-w j" = "workspace::ActivatePaneDown";
              "ctrl-w k" = "workspace::ActivatePaneUp";
              "ctrl-w l" = "workspace::ActivatePaneRight";
              "ctrl-w ctrl-h" = "pane::ActivatePreviousItem";
              "ctrl-w ctrl-l" = "pane::ActivateNextItem";
              "ctrl-t" = "workspace::NewTerminal";
            };
          }
          {
            context = "VimControl && !menu";
            bindings = {
              "ctrl-h" = "pane::ActivatePreviousItem";
              "ctrl-l" = "pane::ActivateNextItem";
              "ctrl-p" = "file_finder::Toggle";
              "ctrl-s" = "workspace::Save";
              "ctrl-x" = "pane::CloseActiveItem";
            };
          }
          {
            context = "VimControl && (vim_mode == normal || vim_mode == visual)";
            bindings = {
              s = "vim::PushSneak";
              "shift-s" = "vim::PushSneakBackward";
            };
          }
          {
            context = "VimControl && vim_mode == normal";
            bindings = {
              "space b l" = "pane::CloseItemsToTheLeft";
              "space b r" = "pane::CloseItemsToTheRight";
              "space b o" = "pane::CloseOtherItems";
              "space f f" = "pane::RevealInProjectPanel";
              "space r n" = "editor::Rename";
              "] d" = "editor::GoToDiagnostic";
              "[ d" = "editor::GoToPreviousDiagnostic";
            };
          }
          {
            context = "Workspace && !Dock";
            bindings = {
              "ctrl-h" = "pane::ActivatePreviousItem";
              "ctrl-l" = "pane::ActivateNextItem";
              "ctrl-p" = "file_finder::Toggle";
              "ctrl-shift-t" = "pane::ReopenClosedItem";
              "ctrl-x" = "pane::CloseActiveItem";
            };
          }
        ];
      };
    };
}
