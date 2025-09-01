{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pawbar;
  yamlFormat = pkgs.formats.yaml { };
in
{
  options = {
    services.pawbar = {
      enable = lib.mkEnableOption "pawbar";
      package = lib.mkPackageOption pkgs "pawbar" { nullable = true; };
      settings = lib.mkOption {
        inherit (yamlFormat) type;
        default = {
          left = { };
          right = { };
        };
        example = lib.literalExpression ''
          left:
            - hyprws
            - hyprtitle

          right:
            - battery
            - space
            - sep
            - space
            - clock
        '';
        description = ''
          Configuration written to {file}`$XDG_CONFIG_HOME/pawbar/pawbar.yaml`.
          See <https://github.com/codelif/pawbar> for more info.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."pawbar/pawbar.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "pawbar.yaml" cfg.settings;
    };

    systemd.user.services.pawbar = {
      Unit = {
        Description = "A kitten-panel based desktop panel for your desktop";
        Documentation = "https://github.com/codelif/pawbar";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
        X-Restart-Triggers = "${config.xdg.configFile."pawbar/pawbar.yaml".source}";
      };

      Service = {
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        ExecStart = "${cfg.package}/bin/pawbar";
        KillMode = "mixed";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
