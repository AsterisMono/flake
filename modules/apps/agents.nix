{
  inputs,
  ...
}:
let
  piSettings = {
    defaultProvider = "deepseek";
    defaultModel = "deepseek-v4-flash";
    hideThinkingBlock = true;
    showCacheMissNotices = true;
    quietStartup = true;
  };

  piAppendSystemPrompt = ''
    Default to using clear, concise paragraphs, each developing one main idea. Use lists only when the information is genuinely parallel, sequential, or easier to compare, and avoid nested lists unless the hierarchy cannot be expressed clearly in prose. Use plain, simple language: familiar words, concrete examples, and precise verbs. Prefer active voice and direct statements.

    Make sure to state the main point clearly and early, then develop it with the explanation and detail the reader needs. Let each sentence build on what came before. Develop the points that matter and provide enough support to be useful.

    Use plain language over jargon, and reference technical details only to the degree that it helps illustrate an idea or your work to the user. Communicate complex concepts in a clear and cohesive manner, and calibrate your writing to the level of background knowledge assumed from the user's prompt and context.

    Avoid using slop words or phrases like "Bottom Line:" in conclusions, "delve," "foster," "leverage," "it's worth noting," "importantly," "Question? Answer." or "This isn't about X. It's about Y.", "genuinely" or hyphenated compound descriptions and adjectives. Do not use concluding summary statements such as "In short:..", "The simplest mental model is:...".

    State the intended action directly. Avoid adding what you won't do, what will remain unchanged, or how you'll separate or categorize results. Do not use contrastive framing such as "X, not Y" or "X—not Y" that introduces an unprompted alternative that the user didn't ask about. Avoid invented compound labels like "exact-head checks" and "editorial-row layouts", vague qualifiers, and canned transitions; use plain verbs and prepositions to state the actual relationship directly.
  '';

  piVendoredNpmPackages = {
    "npm:@ff-labs/pi-fff@0.10.6".hash = "sha256-tuXOO4CbFMXF5ww/NNXvesjPWc6geXJJegQ0YRKlGIU=";
    "npm:@juicesharp/rpiv-todo@2.10.1".hash = "sha256-HJkGPtV9l2tcyFC3ypOpsg+zK30xORBwK/ZAwyQEiXU=";
    "npm:@narumitw/pi-goal@0.54.4".hash = "sha256-u2OIvisWyr70CIDh7Be51eg5PdFN99Pb8vbbDGcAwqQ=";
    "npm:pi-ask-user@0.15.0".hash = "sha256-/U+aH1DCYQAccUUgm24B5vPpxDNQu62zOFPG8av7ykc=";
    "npm:pi-mcp-adapter@2.32.1".hash = "sha256-0TOiEcPV6Ytvhairm8XEB3QvVRuT0Xo/2/dtOeDSHGQ=";
    "npm:pi-web-access@0.29.0".hash = "sha256-0+1o91vuRym/g8jXPfLELWvmsEQE/rbrCV4dxlZ8LAg=";
  };

  herdrSkill = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr/7b675f42af35508eab66ac42fe1598628597a893/skills/herdr/SKILL.md";
    sha256 = "sha256-I3rSqy2BI+K7N5VtOkHu0UHy0ip8NuQVt4dsA5dnkJk=";
  };
in
{
  flake-file.inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  flake.modules.aspects.agents.imports = with inputs.self.modules.aspects; [
    herdr
    pi-agent
  ];

  flake.modules.homeManager.agents =
    { pkgs, ... }:
    let
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      programs = {
        herdr = {
          enable = true;
          plugins.reviewr = pkgs.selfPackages.herdr-reviewr;
          settings = {
            onboarding = false;
            session.resume_agents_on_restore = true;
            keys.command = [
              {
                key = "alt+r";
                type = "plugin_action";
                command = "persiyanov.reviewr.toggle";
              }
            ];
            theme.name = "terminal";
            ui.toast.delivery = "system";
          };
        };

        pi-agent = {
          enable = true;
          package = llmAgents.pi;
          settings = piSettings;
          appendSystemPrompt = piAppendSystemPrompt;
          skills.herdr = herdrSkill;
          vendoredNpmPackages = piVendoredNpmPackages;
        };
      };

      home.packages =
        with llmAgents;
        [
          codex
          cursor-agent
          opencode
          dsh
        ]
        ++ (with pkgs; [
          bubblewrap
          jq
          python3
          selfPackages.zed-delta
        ]);
    };
}
