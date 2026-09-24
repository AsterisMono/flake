{
  flake.modules.homeManager.codex-wrappers =
    { config, ... }:
    {
      # OpenCode Go exposes the Responses API Codex speaks for only part of its
      # catalog, and grok refuses the reasoning items Codex replays, so the
      # catalog holds the one model that answers there and survives a turn.
      programs.codex-wrappers.ocsh = {
        apiKeyEnvironmentVariable = "OPENCODE_API_KEY";
        apiKeyFile = config.constants.resources.userSecretPaths.opencode_api_key;
        modelCatalog = ./ocsh-models.json;
        settings = {
          forced_login_method = "api";
          model = "deepseek-v4.1-flash";
          model_provider = "opencode-go";
          model_reasoning_effort = "high";
          web_search = "disabled";
          model_providers.opencode-go = {
            name = "opencode-go";
            base_url = "https://opencode.ai/zen/go/v1";
            wire_api = "responses";
            env_key = "OPENCODE_API_KEY";
          };
        };
      };
    };
}
