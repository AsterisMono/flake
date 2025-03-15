lib: path:
let
  nixFilesList = lib.mapAttrsToList (fileName: type: {
    name = "payload-" + (lib.removeSuffix ".nix" fileName);
    value = if type == "regular" then path + "/${fileName}" else path + "/${fileName}/default.nix";
  }) (builtins.readDir path);
in
builtins.listToAttrs nixFilesList
