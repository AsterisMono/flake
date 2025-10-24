{
  username,
  secretsPath,
  osConfig,
  ...
}:
let
  homeDirectory = "/home/${username}";
in
{
  imports = osConfig.noa.homeManager.modules;

  programs.home-manager.enable = true;

  home = {
    inherit username homeDirectory;
    sessionVariables = {
      LANG = "zh_CN.UTF-8";
      LANGUAGE = "zh_CN:en_US";
    };
    stateVersion = "24.05";
  };

  sops = {
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = "${secretsPath}/home.yaml";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
