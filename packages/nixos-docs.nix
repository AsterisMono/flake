{ lib, nixosOptionsDoc, modules }:
let
  eval = lib.evalModules {
    modules = [
      {
        _module.check = false;
      }
    ] ++ modules;
  };
in
(nixosOptionsDoc {
  inherit (eval) options;
}).optionsJSON
