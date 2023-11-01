{ flake, ... }:
{
  home-manager.users.cmiki.imports = 
    [ ./home ] ++ [
      flake.inputs.agenix.homeManagerModules.default
      {
        age.identityPaths = [ "/home/cmiki/.ssh/id_ed25519" ];
      }
    ];
}
