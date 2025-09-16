{ unstablePkgs, ... }:
{
  home.packages = with unstablePkgs; [
    xpipe
    socat # xpipe dependency
  ];

  home.file.".xpipe/settings/preferences.json".source = ./preferences.json;
}
