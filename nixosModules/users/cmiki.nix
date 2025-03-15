{ pkgs, type, ... }:
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
    shell = if type == "desktop" then pkgs.fish else pkgs.bashInteractive;
    initialHashedPassword = "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESmYINQDHO1+7FY0mDdcl+UIu2RPuMNOtj242d2N3cf"
    ];
  };
}
