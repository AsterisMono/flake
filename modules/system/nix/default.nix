{ inputs, ... }: {
  flake-file.nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  flake.modules.nixos.nix = { pkgs, ... }: {
    nix = {
      package = pkgs.nix;
      channel.enable = false;
      registry = {
        noa.flake = inputs.self;
      };
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        extra-substituters = [
          "https://cache.numtide.com"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        trusted-users = [ "@wheel" ];
      };

      # Suppress nix-shell channel errors on a flake system
      nixPath = [ "/etc/nix/path" ];

      # do garbage collection weekly to keep disk usage low
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "26.05";
  };
}
