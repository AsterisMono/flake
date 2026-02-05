{
  pkgs,
  unstablePkgs,
  ...
}:
let
  ccnupr = pkgs.writeShellScriptBin "ccnupr" (builtins.readFile ./scripts/ccnupr.sh);
  realize = pkgs.writeShellScriptBin "realize" (builtins.readFile ./scripts/realize.sh);
in
{
  home.packages = with pkgs; [
    # Runtime / Compilers
    nodejs_22
    corepack_22
    devenv
    go
    uv
    bun

    # Language servers
    nixd
    nixfmt-rfc-style
    typescript # tsserver
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server
    yamlfmt
    gopls

    # Scripts
    ccnupr
    realize
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    vimAlias = true;
    package = unstablePkgs.neovim-unwrapped;
  };
  stylix.targets.neovim.enable = false;

  xdg.configFile."opencode/oh-my-opencode.json".source = ./externalConfigs/oh-my-opencode.json;
}
