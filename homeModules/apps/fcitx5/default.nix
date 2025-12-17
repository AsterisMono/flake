{ lib, ... }:
{
  # TODO: Refactor
  xdg.configFile."fcitx5".source = lib.mkForce ./configs;
}
