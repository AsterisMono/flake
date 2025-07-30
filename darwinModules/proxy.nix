{
  config,
  lib,
  pkgs,
  secretsPath,
  ...
}:
let
  httpProxy = "http://127.0.0.1:7890";
  socksProxy = "socks5://127.0.0.1:7890";
  username = config.users.users.cmiki.name;
in
{
  networking.proxy = {
    inherit httpProxy;
    httpsProxy = httpProxy;
    allProxy = socksProxy;
  };

  sops.secrets.mihomoConfig = {
    format = "yaml";
    sopsFile = "${secretsPath}/mihomoConfig.yaml";
    key = "";
    mode = "0400";
    owner = username;
  };

  launchd.user.agents.mihomo = {
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
    serviceConfig.ProgramArguments = [
      (lib.getExe pkgs.mihomo)
      "-d"
      "/Users/${username}/Library/Application Support/mihomo"
      "-f"
      "${config.sops.secrets.mihomoConfig.path}"
    ];
  };

  launchd.user.agents.system-proxy-setup = {
    serviceConfig.RunAtLoad = true;
    script = ''
      networksetup -setwebproxy "Wi-Fi" 127.0.0.1 7890
      networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 7890
      networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 7890
    '';
  };
}
