{ lib, writeShellScriptBin, nixosOptionsDoc, modules, pkgs }:
let
  eval = lib.evalModules {
    modules = [
      {
        _module.check = false;
      }
    ] ++ modules;
  };
  inherit (nixosOptionsDoc {
    inherit (eval) options;
  }) optionsJSON;
in
writeShellScriptBin "nixos-docs"
  # ''
  #   echo \\\(
  # ''
  ''
    jq -r 'keys - ["_module.args"] | .[]' ${optionsJSON} | fzf --preview='jq -r \'def bold(s): "\u001b[1m\\(s)\u001b[0m"; .["{}"] | "\\(bold("Name")): {}\n\n\\(bold("Description")): \\(.description)\n\n\\(bold("Type")): \\(.type)\n\n\\(bold("Default")): \\(.default.text)\n\n\\(bold("Example")): \\(.example.text)"\' ${optionsJSON}'
  ''
