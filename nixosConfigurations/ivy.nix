{ nixosModules, pkgs, ... }:
{
  imports = with nixosModules; [
    roles.server
    services.tailscale
  ];

  noa.nix.enableMirrorSubstituter = true;

  environment.systemPackages = with pkgs; [
    bpftools
    ethtool
    f2fs-tools
    iperf
    lm_sensors
    mtr
    traceroute
    tcpdump
    conntrack-tools
  ];
}
