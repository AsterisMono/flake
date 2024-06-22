{ flake, ... }:
{
  home-manager.users.cmiki.imports = [ ./home ];
}
