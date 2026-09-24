_: {
  flake.modules.homeManager.splayer-next =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.unstable.splayer-next ];
    };
}
