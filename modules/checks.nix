{ config, lib, ... }:
let
  configurations = config.flake.nixosConfigurations;
  configurationsWithoutBase = builtins.filter (
    name: !(lib.hasAttrByPath [ "roles" "base" "imported" ] configurations.${name}.options)
  ) (builtins.attrNames configurations);
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.nixos-configurations-import-base =
        assert lib.assertMsg (configurationsWithoutBase == [ ]) ''
          The following NixOS configurations do not import the base role module:
          ${lib.concatStringsSep ", " configurationsWithoutBase}
        '';
        pkgs.runCommand "nixos-configurations-import-base" { } ''
          touch $out
        '';
    };
}
