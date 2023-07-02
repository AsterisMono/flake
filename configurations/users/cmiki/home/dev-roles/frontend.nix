{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_18
    nodePackages.live-server
    nodePackages.pnpm
    nodePackages.yarn
    nodePackages.typescript-language-server
    nodePackages.svelte-language-server
    vscode-langservers-extracted
  ];
}
