{
  pkgs,
  ...
}:
let
  username = "sugar";
in
{
  users.users."${username}" = {
    isNormalUser = true;
    description = "Asai Neko";
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.bashInteractive;
    initialHashedPassword = "$y$j9T$Z4t5zBrAt0cjjcxka6DWc.$EP6Qq51XqWMtxaEvLgBPGU73UTqR1UVHoyCnbGBDXx0";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1uNblFy06PCgiTFudV/RFLeDzY1xwWjELFIeElAsd02VzurjHSiC8RBNR253ne38+GSagDdeoqYPtAnvQShKzBak+QWQ/pt46pF5Jo25zEXHTxj+W+YGQAHLmeWheoUMLn5LFSN5EfqQxfiV1anh9SAfvpe02BcTO8YTbGdutPAy3mRrL+fL+AhlAKqAIEIJZdOjZJ7KOID4U97LZgC9Q8HTGCPJxGBCtPAAtmMEnI0oSwVA0DatrSMecgE6+U9+ib7TIXkUkJau3zLExCSuDpgNmBQKCuMjtxigfqbuoz7yI/aAxvWie9vUqNy0IqS8XX/CX35eobRlt1of/nsPx"
    ];
  };

  nix.settings.trusted-users = [ username ];
}
