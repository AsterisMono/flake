{ inputs, ... }:
{
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim/nixos-26.05";

  flake.modules.homeManager.neovim = {
    imports = [ inputs.nixvim.homeModules.nixvim ];

    programs.nixvim = {
      enable = true;
      vimAlias = true;
      nixpkgs.source = inputs.nixpkgs;

      imports = [
        (
          { config, lib, ... }:
          let
            luaAction = action: lib.nixvim.mkRaw "function() ${action} end";
          in
          {
            opts = {
              backspace = [
                "start"
                "eol"
                "indent"
              ];
              expandtab = true;
              scrolloff = 10;
              shiftwidth = 2;
              tabstop = 2;
              wildignore = [ "*/node_modules/*" ];
            };

            diagnostic.settings = {
              virtual_text = true;
              signs.text = lib.nixvim.mkRaw ''
                {
                  [vim.diagnostic.severity.ERROR] = "",
                  [vim.diagnostic.severity.WARN] = "",
                  [vim.diagnostic.severity.INFO] = "",
                  [vim.diagnostic.severity.HINT] = "",
                }
              '';
            };

            plugins = {
              mini = {
                enable = true;
                modules = {
                  ai = { };
                  basics = {
                    mappings.windows = true;
                    options.extra_ui = true;
                  };
                  bracketed = { };
                  bufremove = { };
                  cmdline = { };
                  comment = { };
                  completion = { };
                  diff = { };
                  extra = { };
                  icons = { };
                  indentscope.draw.delay = 0;
                  jump = { };
                  move = { };
                  notify = { };
                  pairs = { };
                  pick = { };
                  starter = { };
                  statusline = { };
                  tabline = { };
                  trailspace = { };
                };
              };

              flash = {
                enable = true;
                settings.modes.char.jump_labels = true;
              };

              lspconfig.enable = true;

              treesitter = {
                enable = true;
                highlight.enable = true;
                grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
                  nix
                  yaml
                ];
              };

              conform-nvim = {
                enable = true;
                autoInstall.enable = true;
                settings = {
                  formatters_by_ft = {
                    nix = [ "nixfmt" ];
                    yaml = [ "yamlfmt" ];
                    json = [ "prettier" ];
                  };
                  format_on_save = {
                    timeout_ms = 500;
                    lsp_format = "fallback";
                  };
                };
              };
            };

            lsp.servers = {
              nixd.enable = true;
              yamlls.enable = true;
            };

            keymaps =
              lib.nixvim.keymaps.mkKeymaps
                {
                  mode = "n";
                  options = {
                    silent = true;
                    noremap = true;
                  };
                }
                [
                  {
                    key = "X";
                    action = luaAction "MiniBufremove.delete()";
                  }
                  {
                    key = "<leader>f";
                    action = luaAction "MiniPick.builtin.files()";
                  }
                  {
                    key = "<leader>r";
                    action = luaAction "MiniPick.builtin.grep_live()";
                  }
                  {
                    key = "<leader>b";
                    action = luaAction "MiniPick.builtin.buffers()";
                  }
                  {
                    key = "<leader>R";
                    action = luaAction "MiniPick.builtin.resume()";
                  }
                  {
                    key = "<leader>d";
                    action = luaAction "MiniExtra.pickers.diagnostic()";
                  }
                  {
                    key = "<leader>gh";
                    action = luaAction "MiniExtra.pickers.git_hunks()";
                  }
                  {
                    key = "s";
                    action = luaAction ''require("flash").jump()'';
                  }
                  {
                    mode = "o";
                    key = "r";
                    action = luaAction ''require("flash").remote()'';
                  }
                ];
          }
        )
      ];
    };
  };
}
