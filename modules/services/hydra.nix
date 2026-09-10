{
  flake.modules.nixos.hydra = {
    nix = {
      buildMachines = [
        {
          hostName = "localhost";
          protocol = null;
          system = "x86_64-linux";
          supportedFeatures = [
            "kvm"
            "nixos-test"
            "big-parallel"
            "benchmark"
          ];
          maxJobs = 8;
        }
      ];
      settings.allowed-uris = [
        "github:"
        "git+https://github.com/"
        "git+ssh://github.com/"
      ];
    };

    services.hydra = {
      enable = true;
      hydraURL = "https://hydra.home.arpa.sne.moe";
      notificationSender = "hydra@nvirellia.im";
      useSubstitutes = true;
    };
  };
}
