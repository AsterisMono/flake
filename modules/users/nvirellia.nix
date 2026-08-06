{
  flake-file.inputs = {
    nix-index-database.url = "github:nix-community/nix-index-database";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
  };

  flake.modules.nixos.users-nvirellia =
    { config, pkgs, ... }:
    let
      inherit (config.constants) nvirellia;
    in
    {
      users.users."${nvirellia.username}" = {
        isNormalUser = true;
        description = nvirellia.preferredName;
        extraGroups = [
          "wheel"
          "video"
          "networkmanager"
          "input"
        ];
        shell = pkgs.fish;
        initialHashedPassword = nvirellia.hashedPassword;
        openssh.authorizedKeys.keys = [ nvirellia.sshPubKey ];
      };

      programs.fish.enable = true;

      home-manager = {
        # Entrypoint
        users."${nvirellia.username}".imports = [ ];

        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };
}
