_: {
  flake.modules.homeManager.fish = { pkgs, ... }: {
    programs.fish = {
      enable = true;
      plugins = map (x: { inherit (x) name src; }) (
        with pkgs.fishPlugins;
        [
          plugin-git
          fzf-fish
          puffer
        ]
      );
      shellInit = ''
        set --global --export BASE16_SHELL_SET_BACKGROUND false
        set --global fish_greeting
      '';
      interactiveShellInit = ''
        any-nix-shell fish --info-right | source
      '';
      shellAliases = {
        ".." = "cd ../";
        "n" = "nvim";
        "ls" = "eza -l";
        "l" = "eza -l";
        "ll" = "eza -al";
        "tree" = "eza --tree";
        "gg" = "lazygit";
        "ze" = "zed .";
      };
    };

  };
}
