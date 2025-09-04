flake: final: prev: {
  lib = prev.lib // {
    wrapped = flake.inputs.wrapper-manager.lib.wrapWith final;
    mkNixPak = flake.inputs.nixpak.lib.nixpak {
      inherit (prev) lib;
      pkgs = prev;
    };
  };
}
