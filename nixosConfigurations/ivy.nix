{ nixosModules, pkgs, ... }:
{
  imports = with nixosModules; [
    roles.server
  ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

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
