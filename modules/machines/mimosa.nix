{ inputs, ... }: {
  machines.mimosa = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      server
      efi
      substituter-cn
      podman
      forgejo-runner
      sing-box
      netbird
      nvirellia
      neovim
      unix-tools
      starship
      fish
    ];
    diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
    hardware =
      {
        modulesPath,
        lib,
        config,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ];

        networking = {
          hostName = "mimosa";
          domain = "lotus.local";
          firewall.enable = lib.mkForce false;
        };
        boot.initrd.availableKernelModules = [ "nvme" ];
        boot.initrd.kernelModules = [ "dm-snapshot" ];
        boot.kernelModules = [ "kvm-amd" ];
        boot.extraModulePackages = [ ];
        disko.devices.disk.main.device = "/dev/nvme0n1";

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
  };
}
