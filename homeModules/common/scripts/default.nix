{ pkgs, ... }:
let
  ccnupr = pkgs.writeShellScriptBin "ccnupr" (builtins.readFile ./ccnupr);
in
{
  home.packages = [ ccnupr ];
}
