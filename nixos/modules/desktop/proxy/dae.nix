{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    dae
  ];
}
