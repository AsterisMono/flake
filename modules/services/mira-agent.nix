{
  inputs,
  lib,
  ...
}:
let
  stateDir = "/var/lib/flint-workshop";
in
{
  flake.modules.nixos.mira-agent =
    { config, pkgs, ... }:
    let
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      hermes = llmAgents.hermes-agent;
    in
    {
      environment.systemPackages =
        with llmAgents;
        [
          agent-browser
          ai-memory
          herdr
          hermes-agent
          memvid-cli
          opencode
          qmd
          terminal-use
        ]
        ++ [ pkgs._1password-cli ];

      sops.secrets.mira_agent_op_token = {
        format = "yaml";
        key = "op_service_account_token";
        sopsFile = config.constants.resources.getSecretPath "mira-agent.yaml";
        owner = "mira";
        group = "agent";
        mode = "0400";
      };

      sops.templates."mira-agent.env" = {
        content = "OP_SERVICE_ACCOUNT_TOKEN=${config.sops.placeholder.mira_agent_op_token}\n";
        owner = "mira";
        group = "agent";
        mode = "0400";
        restartUnits = [ "mira-agent.service" ];
      };

      users.users.mira = {
        isSystemUser = true;
        group = "agent";
        home = stateDir;
        description = "Mira agentic service";
      };
      users.groups.agent = { };

      systemd.services.mira-agent = {
        description = "Mira agentic service (Hermes messaging gateway)";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "sops-install-secrets.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "sops-install-secrets.service" ];

        environment = {
          HOME = stateDir;
          HERMES_HOME = stateDir;
          HERMES_SUPERVISED_CHILD = "1";
        };

        path = [ config.system.path ];

        serviceConfig = {
          Type = "simple";
          User = "mira";
          Group = "agent";
          StateDirectory = "flint-workshop";
          EnvironmentFile = config.sops.templates."mira-agent.env".path;
          WorkingDirectory = stateDir;
          ExecStart = "${lib.getExe hermes} gateway run";
          Restart = "always";
          RestartSec = 5;
          RestartForceExitStatus = 75;
          RestartPreventExitStatus = 78;
          KillMode = "mixed";
          KillSignal = "SIGTERM";
          ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
          TimeoutStopSec = 120;
          StandardOutput = "journal";
          StandardError = "journal";

          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ stateDir ];
        };
      };
    };
}
