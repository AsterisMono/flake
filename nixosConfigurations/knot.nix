{
  pkgs,
  inputs,
  nixosModules,
  ...
}:
let
  domain = "knot.requiem.garden";
in
{

  imports = with nixosModules; [
    roles.server
    diskLayouts.gpt-bios-compat
    inputs.tangled-core.nixosModules.knot
  ];

  services.tangled.knot = {
    enable = true;
    package = inputs.tangled-core.packages.${pkgs.stdenv.hostPlatform.system}.knot;
    server = {
      owner = "did:plc:slppfu4tbwhfcomwqjyzwdcc";
      hostname = domain;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      5555
    ];
  };

  disko.devices.disk.main.device = "/dev/sda";
}
