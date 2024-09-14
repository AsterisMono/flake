{ lib, writeShellScriptBin, nixosOptionsDoc, modules, pkgs }:
let
  eval = lib.evalModules {
    modules = [
      {
        _module.check = false;
      }
    ] ++ modules;
  };
  optionsJSONDrv =
    (nixosOptionsDoc {
      inherit (eval) options;
    }).optionsJSON;
  optionsJSON = "${optionsJSONDrv}/share/doc/nixos/options.json";
in
writeShellScriptBin "nixos-docs"
  ''
    ${pkgs.jq}/bin/jq -r 'keys - ["_module.args"] | .[]' ${optionsJSON} | ${pkgs.fzf}/bin/fzf --preview='${pkgs.jq}/bin/jq -r -f ${./filter.jq} --arg key {} ${optionsJSON}'
  ''
