{ arch, flake, ... }:
{
  environment.systemPackages = [ flake.inputs.agenix.packages."${arch}-linux".default ];
  age.identityPaths = [
    /home/cmiki/.ssh/id_ed25519
  ];
}
