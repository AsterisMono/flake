{
  pkgs,
  unstablePkgs,
  ...
}:
let
  ccnupr = pkgs.writeShellScriptBin "ccnupr" (builtins.readFile ./scripts/ccnupr);
in
{
  home.packages = with pkgs; [
    nodejs_22
    corepack_22
    devenv

    # Language servers
    nixd
    nixfmt-rfc-style
    typescript # tsserver
    vscode-langservers-extracted
    yaml-language-server
    yamlfmt

    # Scripts
    ccnupr

    unstablePkgs.gemini-cli
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    package = unstablePkgs.neovim-unwrapped;
  };
}
