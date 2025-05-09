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
}
