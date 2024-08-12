{ username, ... }:
{
  home = {
    username = username;
    language.base = "zh_CN.UTF-8";
    stateVersion = "24.05";
    homeDirectory = "/home/${username}";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
