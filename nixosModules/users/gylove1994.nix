{ pkgs, type, ... }:
{
  programs.zsh.enable = true;

  users.users.gylove1994 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" "wireshark" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcRwbNCfsRvL+xJAQHSFjtH1oFBPpENZ1HxrYbQblxW gylove1994@gengyandemini"
    ];
  };
}
