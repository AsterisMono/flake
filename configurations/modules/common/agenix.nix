{ arch, flake, ... }:
{
  environment.systemPackages = [ flake.inputs.agenix.packages."${arch}-linux".default ];
}