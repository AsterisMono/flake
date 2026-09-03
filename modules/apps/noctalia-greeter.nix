{ inputs, ... }:
{
  flake-file.inputs.noctalia-greeter = {
    url = "github:noctalia-dev/noctalia-greeter";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.noctalia-greeter = {
    imports = [ inputs.noctalia-greeter.nixosModules.default ];

    programs.noctalia-greeter.enable = true;
  };
}
