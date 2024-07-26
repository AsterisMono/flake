flake: final: prev: {
  flakePackages = flake.packages.${prev.system};
}
