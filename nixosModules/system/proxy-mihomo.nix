{ flake, config, pkgs, lib, ... }:
let
  clashProxy = "http://127.0.0.1:7890";
in
{
  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = "${flake.inputs.secrets}/mihomoConfig.yaml";
  };
  # iptables based firewall needs to be disabled
  # NixOS employs firewall by default
  # And it's blocking inbound connections on 192.18.0.1/16
  # Effectively breaking tun mode
  # However NixOS config networking.firewall doesn't support declarative ip-range rules, only ports
  # sus
  networking.firewall.enable = false;
}
