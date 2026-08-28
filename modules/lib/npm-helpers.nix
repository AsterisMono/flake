{ lib, ... }:
let
  defaultNpmFlags = [ "--legacy-peer-deps" ];

  parseNpmSpec =
    npmSpec:
    let
      unversioned = {
        name = npmSpec;
        version = "latest";
      };
    in
    if lib.hasPrefix "@" npmSpec then
      let
        slashParts = lib.splitString "/" npmSpec;
        scope = builtins.elemAt slashParts 0;
        rest = builtins.concatStringsSep "/" (builtins.tail slashParts);
        versionParts = lib.splitString "@" rest;
        package = builtins.elemAt versionParts 0;
      in
      if builtins.length slashParts < 2 || package == "" then
        unversioned
      else
        {
          name = "${scope}/${package}";
          version = if builtins.length versionParts > 1 then builtins.elemAt versionParts 1 else "latest";
        }
    else
      let
        versionParts = lib.splitString "@" npmSpec;
        package = builtins.elemAt versionParts 0;
      in
      if package == "" then
        unversioned
      else
        {
          name = package;
          version = if builtins.length versionParts > 1 then builtins.elemAt versionParts 1 else "latest";
        };

  mkNpmPackage =
    pkgs: source: packageCfg:
    let
      npmSpec = lib.removePrefix "npm:" source;
      package = parseNpmSpec npmSpec;
      npmFlags = packageCfg.npmFlags or defaultNpmFlags;
      pname = "pi-npm-package-${lib.strings.sanitizeDerivationName package.name}";
      packageJson = builtins.toJSON {
        name = pname;
        version = "0.0.0";
        private = true;
        dependencies.${package.name} = package.version;
      };
      packageSrc = pkgs.runCommand "${pname}-src" { } ''
        mkdir -p $out
        printf %s ${lib.escapeShellArg packageJson} > $out/package.json
      '';
      nodeModulesLinkTarget = if lib.hasPrefix "@" package.name then "../.." else "..";
      generateLock = ''
        export HOME=$TMPDIR/home
        export npm_config_cache=$TMPDIR/npm-cache
        mkdir -p "$HOME"
        npm install --package-lock-only --ignore-scripts ${lib.escapeShellArgs npmFlags}
      '';
    in
    pkgs.buildNpmPackage {
      inherit pname npmFlags;
      inherit (package) version;
      src = packageSrc;

      npmDeps = pkgs.fetchNpmDeps {
        name = "${pname}-${package.version}-npm-deps";
        src = packageSrc;
        nativeBuildInputs = [ pkgs.nodejs ];
        NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        postPatch = generateLock;
        inherit (packageCfg) hash;
      };
      dontNpmBuild = true;
      postPatch = ''
        cp "$npmDeps/package-lock.json" package-lock.json
      '';
      installPhase = ''
        runHook preInstall
        test -d ${lib.escapeShellArg "node_modules/${package.name}"}
        mkdir -p "$out"
        cp -R node_modules "$out/node_modules"
        if [ ! -e "$out/node_modules/${package.name}/node_modules" ]; then
          ln -s ${lib.escapeShellArg nodeModulesLinkTarget} "$out/node_modules/${package.name}/node_modules"
        fi
        ln -s ${lib.escapeShellArg "node_modules/${package.name}"} "$out/package"
        runHook postInstall
      '';
    };

  mkVendoredSettings =
    pkgs: settings: vendoredNpmPackages:
    let
      vendoredNpmPackagePaths = lib.mapAttrsToList (
        source: packageCfg: "${mkNpmPackage pkgs source packageCfg}/package"
      ) vendoredNpmPackages;
      existingPackages = settings.packages or [ ];
    in
    {
      inherit vendoredNpmPackagePaths;
      effectiveSettings =
        settings
        // lib.optionalAttrs (vendoredNpmPackagePaths != [ ]) {
          packages = vendoredNpmPackagePaths ++ existingPackages;
        };
    };
in
{
  options.npmHelpers = {
    defaultNpmFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      description = "Default flags passed to npm install when vendoring Pi packages.";
    };

    parseNpmSpec = lib.mkOption {
      type = lib.types.raw;
      internal = true;
      description = "Parse an npm:<name> or npm:<name>@<version> spec.";
    };

    mkNpmPackage = lib.mkOption {
      type = lib.types.raw;
      internal = true;
      description = "Build a vendored npm package for Pi settings.packages.";
    };

    mkVendoredSettings = lib.mkOption {
      type = lib.types.raw;
      internal = true;
      description = "Merge vendored npm package store paths into Pi settings.";
    };
  };

  config.npmHelpers = {
    inherit
      defaultNpmFlags
      parseNpmSpec
      mkNpmPackage
      mkVendoredSettings
      ;
  };
}
