{ pkgs, ... }:
{
  home.packages = with pkgs;[
    prismlauncher # The Prism Launcher flatpak already bundles java.
  ];
}