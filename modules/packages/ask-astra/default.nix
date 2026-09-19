_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.ask-astra =
        pkgs.runCommand "ask-astra"
          {
            meta = {
              description = "Agent skill for consulting GPT-6-Astra through Herdr";
              platforms = pkgs.lib.platforms.all;
            };
          }
          ''
            install -Dm444 ${./SKILL.md} $out/skills/ask-astra/SKILL.md
            install -Dm444 ${./agents/openai.yaml} $out/skills/ask-astra/agents/openai.yaml
          '';
    };
}
