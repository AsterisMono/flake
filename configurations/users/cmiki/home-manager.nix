{ flake, ... }:
{
  home-manager.users.cmiki.imports = [ ./home ];

  home-manager.backupFileExtension = ".bak";
}
