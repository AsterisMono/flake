{
  modulesPath,
  pkgs,
  lib,
  nixosModules,
  ...
}:

{
  imports =
    [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ]
    ++ (with nixosModules; [
      common
      proxy
      users.cmiki
    ]);

  environment.systemPackages = with pkgs; [
    git
    gh
  ];

  users.users.root = {
    isSystemUser = true;
    shell = pkgs.bashInteractive;
    initialHashedPassword = lib.mkForce "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
    openssh.authorizedKeys.keys = lib.mkForce [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGPXhPWInP+CEc8wd+BWUiAqIAAIbF6rYuoZkt0QNiH"
    ];
  };
}
