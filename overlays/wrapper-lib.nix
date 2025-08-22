flake: final: prev: {
  lib = prev.lib // {
    wrapped = flake.inputs.wrapper-manager.lib.wrapWith final;
  };
}
