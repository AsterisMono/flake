{
  config,
  lib,
  pkgs,
  secretsPath,
  ...
}:
{
  sops.secrets.mihomoConfig = {
    format = "yaml";
    sopsFile = "${secretsPath}/mihomoConfig.yaml";
    key = "";
    mode = "0400";
    owner = "root";
  };

  launchd.daemons.mihomo = {
    serviceConfig = {
      Label = "mihomo";
      RunAtLoad = true;
      LimitLoadToSessionType = "System";
      ProgramArguments = [
        (lib.getExe pkgs.mihomo)
        "-d"
        "/Library/Application Support/mihomo"
        "-f"
        "${config.sops.secrets.mihomoConfig.path}"
      ];
      WorkingDirectory = "/Library/Application Support/mihomo/";
      StandardOutPath = "/Library/Application Support/mihomo/log.out";
      StandardErrorPath = "/Library/Application Support/mihomo/log.err";
    };
  };
}
