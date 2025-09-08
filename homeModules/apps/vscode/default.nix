{ unstablePkgs, lib, ... }:
{
  programs.vscode = {
    enable = true;
    package = unstablePkgs.vscodium;
    mutableExtensionsDir = false;
    profiles.default = {
      userSettings = {
        "[css]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[html]" = {
          "editor.defaultFormatter" = "vscode.html-language-features";
        };
        "[javascript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[javascriptreact]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[json]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[jsonc]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[markdown]" = {
          "editor.defaultFormatter" = "yzhang.markdown-all-in-one";
        };
        "[prisma]" = {
          "editor.defaultFormatter" = "Prisma.prisma";
        };
        "[python]" = {
          "editor.formatOnType" = true;
          "editor.defaultFormatter" = "ms-python.black-formatter";
          "editor.formatOnSave" = true;
          "editor.tabSize" = 4;
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[yaml]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
          "editor.tabSize" = 4;
          "editor.detectIndentation" = false;
        };
        "debug.javascript.autoAttachFilter" = "disabled";
        "diffEditor.ignoreTrimWhitespace" = false;
        "editor.acceptSuggestionOnEnter" = "smart";
        "editor.accessibilitySupport" = "off";
        "editor.bracketPairColorization.enabled" = true;
        "editor.codeActionsOnSave" = {
          "source.addMissingImports" = "explicit";
          "source.fixAll" = "explicit";
          "source.organizeImports.biome" = "explicit";
          "source.fixAll.biome" = "explicit";
          "source.removeUnusedImports" = "explicit";
        };
        "editor.cursorBlinking" = "solid";
        "editor.cursorSurroundingLines" = 5;
        "editor.fontVariations" = false;
        "editor.fontSize" = lib.mkForce 14.0;
        "editor.fontWeight" = "normal";
        "editor.formatOnPaste" = true;
        "editor.formatOnSave" = true;
        "editor.formatOnType" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.inlineSuggest.enabled" = true;
        "editor.lineHeight" = 1.6;
        "editor.linkedEditing" = true;
        "editor.minimap.enabled" = false;
        "editor.quickSuggestions" = {
          strings = "on";
        };
        "editor.smoothScrolling" = true;
        "editor.stickyScroll.enabled" = true;
        "editor.suggest.snippetsPreventQuickSuggestions" = false;
        "editor.suggestSelection" = "first";
        "editor.tabSize" = 2;
        "editor.unicodeHighlight.nonBasicASCII" = false;
        "editor.wordWrap" = "on";
        "explorer.autoReveal" = false;
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;
        "explorer.fileNesting.patterns" = {
          "*.ts" = "\${capture}.js";
          "*.js" = "\${capture}.js.map, \${capture}.min.js, \${capture}.d.ts";
          "*.jsx" = "\${capture}.js";
          "*.tsx" = "\${capture}.ts";
          "tsconfig.json" = "tsconfig.*.json";
          "package.json" = "package-lock.json, yarn.lock, pnpm-lock.yaml, bun.lockb, bun.lock";
          "Cargo.toml" = "Cargo.lock";
          "*.sqlite" = "\${capture}.\${extname}-*";
          "*.db" = "\${capture}.\${extname}-*";
          "*.sqlite3" = "\${capture}.\${extname}-*";
          "*.db3" = "\${capture}.\${extname}-*";
          "*.sdb" = "\${capture}.\${extname}-*";
          "*.s3db" = "\${capture}.\${extname}-*";
        };
        "extensions.experimental.affinity" = {
          "vscodevim.vim" = 1;
          "asvetliakov.vscode-neovim" = 1;
        };
        "files.autoGuessEncoding" = true;
        "files.autoSaveWhenNoErrors" = true;
        "files.exclude" = {
          "**/.classpath" = true;
          "**/.project" = true;
          "**/.settings" = true;
          "**/.factorypath" = true;
          "**/.DS_Store" = true;
          "**/.direnv" = true;
        };
        "git.autoStash" = true;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;
        "git.replaceTagsWhenPull" = true;
        "http.proxy" = "http://127.0.0.1:7890";
        "javascript.preferences.importModuleSpecifier" = "non-relative";
        "javascript.suggest.autoImports" = true;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "liveServer.settings.donotVerifyTags" = true;
        "liveServer.settings.port" = 23333;
        "markdown.preview.breaks" = true;
        "markdownlint.config" = {
          MD026 = false;
        };
        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "nixfmt";
        "nix.hiddenLanguageServerErrors" = [
          "textDocument/definition"
          "textDocument/codeAction"
          "textDocument/documentSymbol"
          "textDocument/inlayHint"
          "textDocument/documentLink"
        ];
        "nix.serverPath" = "nixd";
        "notebook.cellToolbarLocation" = {
          default = "right";
          codebook = "right";
        };
        "notebook.markup.fontSize" = 16;
        "prettier.tabWidth" = 2;
        "projectManager.git.baseFolders" = [
          "/Users/cmiki/Projects"
          "/Users/cmiki/SideProjects"
          "/home/cmiki/repos"
          "/home/cmiki/Projects"
        ];
        "redhat.telemetry.enabled" = false;
        "remote.SSH.localServerDownload" = "always";
        "search.smartCase" = true;
        "security.workspace.trust.untrustedFiles" = "open";
        "terminal.integrated.allowChords" = false;
        "terminal.integrated.cursorBlinking" = false;
        "terminal.integrated.cursorStyle" = "line";
        "terminal.integrated.cursorStyleInactive" = "line";
        "terminal.integrated.cursorWidth" = 2;
        "terminal.integrated.defaultProfile.osx" = "fish";
        "terminal.integrated.env.linux" = {
        };
        "terminal.integrated.env.osx" = {
        };
        "terminal.integrated.env.windows" = {
        };
        "terminal.integrated.fontFamily" = "FiraCode Nerd Font Mono";
        "terminal.integrated.fontSize" = lib.mkForce 13;
        "terminal.integrated.fontWeight" = "normal";
        "terminal.integrated.gpuAcceleration" = "off";
        "typescript.locale" = "en";
        "typescript.preferences.importModuleSpecifier" = "non-relative";
        "typescript.suggest.autoImports" = true;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "update.mode" = "none";
        "vscode-office.editorLanguage" = "zh_CN";
        "vscode-office.editorTheme" = "Auto";
        "window.commandCenter" = false;
        "window.customTitleBarVisibility" = "auto";
        "window.menuBarVisibility" = "compact";
        "window.titleBarStyle" = "custom";
        "window.zoomPerWindow" = false;
        "workbench.activityBar.location" = "hidden";
        "workbench.colorCustomizations" = {
          "terminal.background" = "#00000000";
        };
        "workbench.commandPalette.experimental.suggestCommands" = true;
        "workbench.editor.empty.hint" = "hidden";
        "workbench.editor.pinnedTabsOnSeparateRow" = true;
        "workbench.editor.wrapTabs" = true;
        "workbench.editorAssociations" = {
          "*.copilotmd" = "vscode.markdown.preview.editor";
          "{hexdiff}:/**/*.*" = "hexEditor.hexedit";
          "*.jpg" = "imagePreview.previewEditor";
          "*.db" = "sqlite-viewer.option";
          "*.md" = "default";
          "{git,gitlens}:/**/*.{md,csv}" = "default";
          "*.csv" = "default";
          "*.svg" = "default";
        };
        "workbench.iconTheme" = "file-icons-colourless";
        "workbench.layoutControl.enabled" = false;
        "workbench.secondarySideBar.defaultVisibility" = "hidden";
        "workbench.settings.applyToAllProfiles" = [
          "workbench.colorCustomizations"
        ];
        "workbench.sideBar.location" = "right";
        "workbench.startupEditor" = "none";
        "workbench.tree.enableStickyScroll" = true;
      };
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with unstablePkgs.vscode-marketplace; [
        aaron-bond.better-comments
        alefragnani.project-manager
        astro-build.astro-vscode
        bierner.markdown-mermaid
        bradlc.vscode-tailwindcss
        chrisdias.vscode-opennewinstance
        christian-kohler.path-intellisense
        clinyong.vscode-css-modules
        csstools.postcss
        cweijan.vscode-office
        davidanson.vscode-markdownlint
        dbaeumer.vscode-eslint
        docker.docker
        donjayamanne.python-environment-manager
        editorconfig.editorconfig
        esbenp.prettier-vscode
        file-icons.file-icons
        fill-labs.dependi
        frhtylcn.pythonsnippets
        golang.go
        gruntfuggly.todo-tree
        ibm.output-colorizer
        jnoortheen.nix-ide
        kisstkondoros.vscode-gutter-preview
        mechatroner.rainbow-csv
        mgesbert.python-path
        mgmcdermott.vscode-language-babel
        mikestead.dotenv
        mkhl.direnv
        ms-azuretools.vscode-containers
        ms-ceintl.vscode-language-pack-zh-hans
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode.hexeditor
        ms-vscode.remote-explorer
        ms-vscode.remote-repositories
        ms-vscode.remote-server
        ms-vscode.vscode-js-profile-flame
        ms-vscode.vscode-typescript-next
        ms-vsliveshare.vsliveshare
        mylesmurphy.prettify-ts
        naumovs.color-highlight
        openai.chatgpt
        orta.vscode-jest
        pranaygp.vscode-css-peek
        prisma.prisma
        qufiwefefwoyn.inline-sql-syntax
        qwtel.sqlite-viewer
        redhat.vscode-yaml
        ritwickdey.liveserver
        rust-lang.rust-analyzer
        signageos.signageos-vscode-sops
        skellock.just
        styled-components.vscode-styled-components
        tamasfe.even-better-toml
        telesoho.vscode-markdown-paste-image
        timonwong.shellcheck
        tombonnike.vscode-status-bar-format-toggle
        unifiedjs.vscode-mdx
        usernamehw.errorlens
        visualstudioexptteam.intellicode-api-usage-examples
        visualstudioexptteam.vscodeintellicode
        vitest.explorer
        wayou.vscode-todo-highlight
        xabikos.javascriptsnippets
        xlthu.pangu-markdown
        yzhang.markdown-all-in-one
        zamerick.vscode-caddyfile-syntax
        zignd.html-css-class-completion
      ];
    };
  };
}
