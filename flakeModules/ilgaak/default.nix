{ config, lib, self, ... }:
{
  options = {
    ilgaak = {
      enable = lib.mkEnableOption "Generate package for exploring module options";
      moduleSets = lib.mkOption {
        type = with lib.types; listOf attrs;
        description = "List of module sets to include";
        example = [
          {
            name = "nixos";
            modules = [
              ./modules/nixos.nix
            ];
          }
        ];
        default = [
          {
            name = "nixos";
            modules = lib.attrValues self.nixosModules;
          }
        ];
      };
    };
  };

  config = lib.mkIf config.ilgaak.enable {
    perSystem = { pkgs, ... }: {
      packages = builtins.listToAttrs (map
        (moduleSet: {
          name = "ilgaak-${moduleSet.name}";
          value = pkgs.callPackage ./viewer.nix {
            inherit (moduleSet) modules;
          };
        })
        config.ilgaak.moduleSets
      );
    };
  };
}
