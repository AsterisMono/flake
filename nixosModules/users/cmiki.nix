{
  pkgs,
  config,
  ...
}:
{
  users.users.cmiki = {
    isNormalUser = true;
    description = "Chatnoir Miki";
    extraGroups = [
      "wheel"
      "video"
      "docker"
      "networkmanager"
      "input"
      "wireshark"
    ];
    shell = if config.amono.homeManager.enable then pkgs.fish else pkgs.bashInteractive;
    initialHashedPassword = "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
  };
}
