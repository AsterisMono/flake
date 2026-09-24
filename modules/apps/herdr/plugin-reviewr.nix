{
  flake.modules.homeManager.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.herdr.reviewr;
    in
    {
      options.programs.herdr.reviewr = {
        enable = lib.mkEnableOption "the reviewr Herdr plugin and its pane toggle key";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.selfPackages.herdr-reviewr;
          defaultText = lib.literalExpression "pkgs.selfPackages.herdr-reviewr";
          description = ''
            The reviewr plugin directory to link. Its pane runs the binary
            under $out/bin, so it must be the package built for this machine.
          '';
        };

        key = lib.mkOption {
          type = lib.types.str;
          default = "alt+r";
          description = ''
            The key that toggles the reviewr pane
            (`persiyanov.reviewr.toggle`).
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        programs.herdr.plugins.herdr-reviewr = cfg.package;

        programs.herdr.pluginSettings = [
          (settings: {
            keys.command = (settings.keys.command or [ ]) ++ [
              {
                inherit (cfg) key;
                type = "plugin_action";
                command = "persiyanov.reviewr.toggle";
              }
            ];
          })
        ];
      };
    };
}
