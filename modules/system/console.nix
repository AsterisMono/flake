{
  flake.modules.nixos.console =
    { pkgs, ... }:
    {
      boot.loader.systemd-boot.consoleMode = "max";
      services.kmscon = {
        enable = true;
        hwRender = true;
        extraConfig = ''
          font-size=24
          multi-monitor=largest
        '';
        fonts = [
          {
            name = "Fira Code";
            package = pkgs.fira-code;
          }
        ];
      };
    };
}
