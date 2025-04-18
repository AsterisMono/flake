# Copy & pasted https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/networking.nix
{
  lib,
  config,
  ...
}:
let
  cfg = config.networking;
  opt = lib.options.networking;
in
{
  options = {
    networking.proxy = {
      default = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = lib.mdDoc ''
          This option specifies the default value for httpProxy, httpsProxy, ftpProxy and rsyncProxy.
        '';
        example = "http://127.0.0.1:3128";
      };

      httpProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        inherit (cfg.proxy) default;
        defaultText = lib.literalExpression "config.${opt.proxy.default}";
        description = lib.mdDoc ''
          This option specifies the http_proxy environment variable.
        '';
        example = "http://127.0.0.1:3128";
      };

      httpsProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        inherit (cfg.proxy) default;
        defaultText = lib.literalExpression "config.${opt.proxy.default}";
        description = lib.mdDoc ''
          This option specifies the https_proxy environment variable.
        '';
        example = "http://127.0.0.1:3128";
      };

      ftpProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        inherit (cfg.proxy) default;
        defaultText = lib.literalExpression "config.${opt.proxy.default}";
        description = lib.mdDoc ''
          This option specifies the ftp_proxy environment variable.
        '';
        example = "http://127.0.0.1:3128";
      };

      rsyncProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        inherit (cfg.proxy) default;
        defaultText = lib.literalExpression "config.${opt.proxy.default}";
        description = lib.mdDoc ''
          This option specifies the rsync_proxy environment variable.
        '';
        example = "http://127.0.0.1:3128";
      };

      allProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        inherit (cfg.proxy) default;
        defaultText = lib.literalExpression "config.${opt.proxy.default}";
        description = lib.mdDoc ''
          This option specifies the all_proxy environment variable.
        '';
        example = "http://127.0.0.1:3128";
      };

      noProxy = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = lib.mdDoc ''
          This option specifies the no_proxy environment variable.
          If a default proxy is used and noProxy is null,
          then noProxy will be set to 127.0.0.1,localhost.
        '';
        example = "127.0.0.1,localhost,.localdomain";
      };

      envVars = lib.mkOption {
        type = lib.types.attrs;
        internal = true;
        default = { };
        description = lib.mdDoc ''
          Environment variables used for the network proxy.
        '';
      };
    };
  };

  config = {
    networking.proxy.envVars =
      lib.optionalAttrs (cfg.proxy.default != null) {
        # other options already fallback to proxy.default
        no_proxy = "127.0.0.1,localhost";
      }
      // lib.optionalAttrs (cfg.proxy.httpProxy != null) {
        http_proxy = cfg.proxy.httpProxy;
      }
      // lib.optionalAttrs (cfg.proxy.httpsProxy != null) {
        https_proxy = cfg.proxy.httpsProxy;
      }
      // lib.optionalAttrs (cfg.proxy.rsyncProxy != null) {
        rsync_proxy = cfg.proxy.rsyncProxy;
      }
      // lib.optionalAttrs (cfg.proxy.ftpProxy != null) {
        ftp_proxy = cfg.proxy.ftpProxy;
      }
      // lib.optionalAttrs (cfg.proxy.allProxy != null) {
        all_proxy = cfg.proxy.allProxy;
      }
      // lib.optionalAttrs (cfg.proxy.noProxy != null) {
        no_proxy = cfg.proxy.noProxy;
      };

    # Install the proxy environment variables
    environment.variables = cfg.proxy.envVars;
    launchd.daemons."nix-daemon".environment = cfg.proxy.envVars;
  };
}
