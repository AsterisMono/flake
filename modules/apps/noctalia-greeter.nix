{ inputs, ... }:
{
  flake-file.inputs.noctalia-greeter = {
    url = "github:noctalia-dev/noctalia-greeter";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.noctalia-greeter =
    { config, ... }:
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      programs.noctalia-greeter = {
        enable = true;
        settings = {
          session.default = "Sway (UWSM)";
          user.default = config.constants.nvirellia.username;
          idle.timeout = 300;
          keyboard = {
            layout = "us";
            options = "ctrl:nocaps";
          };
        };
      };
    };
}
