{
  modulesPath,
  pkgs,
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
    description = "Seed.";
    shell = pkgs.bashInteractive;
    initialHashedPassword = "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGPXhPWInP+CEc8wd+BWUiAqIAAIbF6rYuoZkt0QNiH"
    ];
  };
}
