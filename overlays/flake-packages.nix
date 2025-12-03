flake: final: prev: {
  flakePackages = flake.packages.${prev.stdenv.hostPlatform.system};
}
