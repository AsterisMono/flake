{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};

      # Delta dlopens these at runtime rather than linking them directly, so
      # they are injected through the wrapper's LD_LIBRARY_PATH.
      runtimeLibraries = with pkgs; [
        libGL
        vulkan-loader
        wayland
      ];
    in
    {
      packages.zed-delta = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "zed-delta";
        version = "0.16.0";

        src = pkgs.fetchurl {
          url = "https://r2.requiem.garden/delta-linux-x86_64.tar.gz";
          hash = "sha256-CJdYlrkxL7xK1cIp9bCxDoyU8QEImNnFAihzBEIAVTw=";
        };

        # The bundle is a generic glibc ELF tree with its own RPATH
        # ($ORIGIN/../lib) and vendored xcb/xkb libraries. Repatch it into the
        # store instead of building Zed from source.
        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
        ];

        buildInputs = [
          pkgs.glibc
          pkgs.libunwind
        ];

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/libexec/delta
          cp -a . $out/libexec/delta/
          chmod -R u+w $out/libexec/delta

          install -Dm644 $out/libexec/delta/share/applications/dev.zed.Delta.desktop \
            $out/share/applications/dev.zed.Delta.desktop
          substituteInPlace $out/share/applications/dev.zed.Delta.desktop \
            --replace-fail 'Exec=delta ' "Exec=$out/bin/delta "
          cp -a $out/libexec/delta/share/icons $out/share/

          makeWrapper $out/libexec/delta/bin/delta $out/bin/delta \
            --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeLibraries} \
            --suffix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs ]}

          runHook postInstall
        '';

        passthru.fhs = pkgs.buildFHSEnv {
          name = "delta";
          targetPkgs =
            pkgs:
            (with pkgs; [
              glibc
              openssl
              libcap
              zlib
            ]);
          runScript = "${finalAttrs.finalPackage}/bin/delta";
          extraInstallCommands = ''
            ln -s ${finalAttrs.finalPackage}/share "$out/"
          '';
          meta = finalAttrs.meta // {
            description = ''
              Wrapped variant of ${finalAttrs.pname} that launches in an FHS
              environment, allowing extensions and agent tooling to run
              prebuilt binaries.
            '';
          };
        };

        meta = {
          description = "AI-native code editor from the creators of Zed";
          longDescription = ''
            Delta is a multiplayer environment for coding with agents, built
            on the Zed editor. It exposes threads that pair an agent
            conversation with the repository checkout it works in.
          '';
          homepage = "https://delta.dev";
          # Delta ships only a prebuilt, source-less beta binary, so it cannot
          # be treated as free software here.
          license = pkgs.lib.licenses.unfree;
          sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
          mainProgram = "delta";
          platforms = [ "x86_64-linux" ];
        };
      });
    };
}
