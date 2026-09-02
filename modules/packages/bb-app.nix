{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      electron = pkgs.electron_41;
      nodejs = pkgs.nodejs_24;
      pnpm = pkgs.pnpm_11.override { nodejs-slim = nodejs; };
      runtimePath = pkgs.lib.makeBinPath [
        pkgs.gitMinimal
        nodejs
      ];
    in
    {
      packages.bb-app = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "bb-app";
        version = "0.40.0";

        src = pkgs.fetchFromGitHub {
          owner = "get-bb";
          repo = "bb";
          tag = "desktop-v${finalAttrs.version}";
          hash = "sha256-OL/fnDRu+9HaoTpcBl82AoBTpULgB87DqKQ6QdaB1hA=";
        };

        patches = [
          # Convert patched-dependency hashes to the pnpm 11 format.
          ./bb-app-pnpm-lock.yaml.patch
        ];

        # pnpm 11 expects these settings in pnpm-workspace.yaml rather than package.json.
        # Keep them in sync with the upstream package.json until upstream migrates.
        postPatch = ''
          substituteInPlace package.json \
            --replace-fail '"packageManager": "pnpm@9.15.0"' \
            '"packageManager": "pnpm@${pnpm.version}"'

          # Updates are managed by Nix. The afterPack hook downloads native
          # prebuilds, which are compiled from source below instead.
          substituteInPlace apps/desktop/src/desktop-auto-update.ts \
            --replace-fail 'return args.isPackaged || args.env.BB_DESKTOP_AUTO_UPDATE === "1";' \
            'return args.isPackaged && false;'
          substituteInPlace apps/desktop/src/main.ts \
            --replace-fail '(app.isPackaged || process.env.BB_DESKTOP_VERSION_CHECK === "1")' \
            'false' \
            --replace-fail 'app.isPackaged' \
            '(app.isPackaged || process.env.NIX_BB_DESKTOP === "1")' \
            --replace-fail '"Desktop auto-install is disabled: only the Linux AppImage build can replace itself. Version checks still report new releases.",' \
            '"Desktop updates are managed by Nix.",'
          substituteInPlace apps/desktop/electron-builder.config.json \
            --replace-fail '  "afterPack": "scripts/prepare-native-modules.cjs",' ""

          cat >> pnpm-workspace.yaml <<'EOF'

          supportedArchitectures:
            os:
              - current
            cpu:
              - arm64
              - x64
          overrides:
            zod: 4.3.6
            "@expo/metro-config>lightningcss": 1.30.1
          patchedDependencies:
            expo-modules-jsi@57.0.4: patches/expo-modules-jsi@57.0.4.patch
            oniguruma-to-es@4.3.4: patches/oniguruma-to-es@4.3.4.patch
            "@pierre/diffs@1.2.9": patches/@pierre__diffs@1.2.9.patch
          EOF
        '';

        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (finalAttrs)
            pname
            version
            src
            patches
            postPatch
            ;
          inherit pnpm;
          fetcherVersion = 4;
          hash = "sha256-XNki/XuGyxBB/GEg2/zWDdU73lt7CNjOwgCky2OW97w=";
        };

        env = {
          ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
          pnpm_config_manage_package_manager_versions = "false";
        };

        nativeBuildInputs = [
          pkgs.copyDesktopItems
          pkgs.makeWrapper
          nodejs
          pkgs.pkg-config
          pnpm
          pkgs.pnpmConfigHook
          pkgs.python3
        ];

        buildPhase = ''
          runHook preBuild

          export BB_DESKTOP_BUILD_DATE="1970-01-01T00:00:00.000Z"
          export BB_DESKTOP_COMMIT=${finalAttrs.src.rev}

          pnpm build
          pnpm --dir apps/desktop run build

          export npm_config_nodedir=${electron.headers}
          export npm_config_runtime=electron
          export npm_config_target=${electron.version}

          while IFS= read -r packageJson; do
            packageDir="''${packageJson%/package.json}"
            (
              cd "$packageDir"
              node ${pnpm}/libexec/pnpm/dist/node_modules/node-gyp/bin/node-gyp.js rebuild --release
            )
          done < <(find node_modules/.pnpm \( -path '*/node_modules/better-sqlite3/package.json' -o -path '*/node_modules/node-pty/package.json' \))

          cp -r ${electron.dist} electron-dist
          chmod -R u+w electron-dist

          pushd apps/desktop
          pnpm exec electron-builder \
            --dir \
            --linux \
            --x64 \
            --config electron-builder.config.json \
            -c.electronDist="$(pwd)/../../electron-dist" \
            -c.electronVersion=${electron.version} \
            -c.npmRebuild=false
          popd

          appUnpacked=apps/desktop/release/linux-unpacked/resources/app.asar.unpacked
          find "$appUnpacked/node_modules" -path '*/node-pty/lib/unixTerminal.js' -print0 \
            | xargs -0 --no-run-if-empty sed -i \
              "s/helperPath = helperPath.replace('app.asar', 'app.asar.unpacked');/helperPath = helperPath.replace(\/app\\.asar(?!\\.unpacked)\/g, 'app.asar.unpacked');/"
          find "$appUnpacked/node_modules" -path '*/node-pty/build/Release/spawn-helper' -exec chmod 755 {} +

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/bb-app
          cp -r apps/desktop/release/linux-unpacked/{locales,resources{,.pak}} $out/share/bb-app

          install -Dm644 apps/desktop/assets/icon.png \
            $out/share/icons/hicolor/1024x1024/apps/bb-app.png

          makeWrapper ${pkgs.lib.getExe electron} $out/bin/bb-app \
            --add-flags $out/share/bb-app/resources/app.asar \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
            --prefix PATH : ${runtimePath} \
            --set NIX_BB_DESKTOP 1 \
            --inherit-argv0

          runHook postInstall
        '';

        desktopItems = [
          (pkgs.makeDesktopItem {
            name = "bb-app";
            desktopName = "bb";
            comment = finalAttrs.meta.description;
            exec = "bb-app %U";
            icon = "bb-app";
            categories = [ "Development" ];
            startupWMClass = "bb";
            terminal = false;
          })
        ];

        passthru.updateScript = pkgs.nix-update-script {
          extraArgs = [
            "--version=stable"
            "--version-regex=^desktop-v(.*)$"
          ];
        };

        meta = {
          description = "Agentic IDE that builds itself";
          homepage = "https://getbb.app";
          changelog = "https://github.com/get-bb/bb/releases/tag/${finalAttrs.src.tag}";
          license = pkgs.lib.licenses.mit;
          mainProgram = "bb-app";
          platforms = [ "x86_64-linux" ];
        };
      });
    };
}
