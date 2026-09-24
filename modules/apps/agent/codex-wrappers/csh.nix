{
  flake.modules.homeManager.codex-wrappers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.codex-wrappers.csh = {
        apiKeyEnvironmentVariable = "DEEPSEEK_API_KEY";
        apiKeyFile = config.constants.resources.userSecretPaths.deepseek_api_key;
        modelCatalog = ./csh-models.json;
        settings = {
          model = "deepseek-flash";
          model_provider = "deepseek";
          forced_login_method = "api";
          model_reasoning_effort = "high";
          web_search = "disabled";
          non_prefixed_mcp_tool_servers = [ "web" ];
          mcp_servers.web = {
            command = lib.getExe pkgs.selfPackages.csh-web-search;
            env_vars = [ "DEEPSEEK_API_KEY" ];
          };
          model_providers.deepseek = {
            name = "deepseek";
            base_url = "https://api.deepseek.com/";
            wire_api = "responses";
            env_key = "DEEPSEEK_API_KEY";
          };
        };
      };
    };
}
