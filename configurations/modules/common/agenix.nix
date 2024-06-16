{ arch, flake, ... }:
{
  environment.systemPackages = [ flake.inputs.agenix.packages."${arch}-linux".default ];
  age.identityPath = [
    /home/cmiki/.ssh/id_ed25519
  ];
}
