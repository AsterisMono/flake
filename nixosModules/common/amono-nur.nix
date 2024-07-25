{ flake, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      amono-nur = flake.inputs.myNurPackages.packages."${prev.system}";
    })
  ];
}
