{ inputs, lib, ... }: {
  machines.mira = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      server
      efi
      i18n
      substituter-cn
      podman
      sing-box
      netbird
      mira-agent
      honcho
    ];
    diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;

    # The server role turns fontconfig off ("no need for fonts on a server"),
    # but the browser toolset renders pages *on this host*, and Chromium with
    # no fonts finds nothing to draw: every screenshot comes back as flat
    # background. Force it back on for this machine only, and keep the set
    # deliberately smaller than the workstation `fonts` aspect (Latin, CJK for
    # the zh_CN Slack workspace, emoji) — a headless browser has no use for
    # source-han-* or the nerd fonts. ~124 MiB of closure.
    nixosModule =
      { pkgs, ... }:
      {
        fonts = {
          fontconfig.enable = lib.mkForce true;
          packages = with pkgs; [
            dejavu_fonts
            noto-fonts
            noto-fonts-cjk-sans
            twitter-color-emoji
          ];
        };
      };

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
          hostName = "mira";
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
