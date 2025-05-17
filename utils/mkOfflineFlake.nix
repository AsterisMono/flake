{ flake, pkgs }:
let
  inherit (pkgs) lib;
  flakeLock = lib.importJSON "${flake}/flake.lock";
  withSrc =
    node:
    builtins.mapAttrs (
      name: value:
      value
      // {
        drv =
          if name == "root" then
            flake
          else if value.locked.type == "github" then
            pkgs.fetchFromGitHub {
              inherit (value.locked) owner repo rev;
              hash = value.locked.narHash;
            }
          else
            pkgs.fetchgit {
              inherit (value.locked) url rev;
              hash = value.locked.narHash;
            };
      }
    ) node;
  nodes = withSrc flakeLock.nodes;
  rootNode = nodes.root;
  getNodeByInputPath =
    let
      byPathType = {
        "string" = nodeName: nodes."${nodeName}";
        "list" =
          pathList:
          (builtins.foldl' (acc: elem: (getNodeByInputPath acc.inputs."${elem}")) rootNode pathList);
      };
    in
    path: (builtins.getAttr (builtins.typeOf path) byPathType) path;
  collectInputs =
    {
      node,
      prefixList,
      collection,
    }:
    if builtins.hasAttr "inputs" node then
      builtins.concatLists (
        lib.attrsets.mapAttrsToList (
          originalInputName: inputPath:
          let
            nextNode = getNodeByInputPath inputPath;
          in
          collectInputs {
            node = nextNode;
            prefixList = prefixList ++ [ originalInputName ];
            collection = collection ++ [
              {
                overridePath = builtins.concatStringsSep "/" (prefixList ++ [ originalInputName ]);
                inherit (nextNode) drv;
              }
            ];
          }
        ) node.inputs
      )
    else
      collection;
in
rec {
  inputOverrides = lib.lists.unique (collectInputs {
    node = rootNode;
    prefixList = [ ];
    collection = [ ];
  });
  collectedInputDrvs = lib.lists.unique (map (attr: attr.drv) inputOverrides);
  overrideFlags = builtins.concatStringsSep " " (
    map (o: "--override-input ${o.overridePath} ${o.drv}") inputOverrides
  );
}
