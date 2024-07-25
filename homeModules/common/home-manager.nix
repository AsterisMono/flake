{ flake, ... }:

{
  programs.home-manager.enable = true;

  home = {
    username = "cmiki";
    language.base = "zh_CN.UTF-8";
    stateVersion = "24.05";
  };
}
