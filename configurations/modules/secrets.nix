# This file is NOT imported into NixOS configuration.
let
  cmiki = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESmYINQDHO1+7FY0mDdcl+UIu2RPuMNOtj242d2N3cf";
in
{
  "tailscale-authkey".publicKeys = [ cmiki ];
}  