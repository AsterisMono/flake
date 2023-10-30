{ system, ... }:
{
  environment.systemPackages = [ agenix.packages.${system}.default ];
}