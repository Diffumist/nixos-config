{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "bub";
  stateDir = "/var/lib/bub";
  configTemplate = config.sops.templates."bub-config.yml";
  hasBubSecrets = lib.hasInfix "bub:" (builtins.readFile ../secrets.yaml);
  secretOr =
    name: fallback: if hasBubSecrets then config.sops.placeholder."bub/${name}" else fallback;
in
{
  warnings = lib.optional (!hasBubSecrets) ''
    hostdzire Bub is using placeholder Telegram settings.
    Add bub.telegram_bot_token, bub.telegram_allow_users, and/or
    bub.telegram_allow_chats to nixos/hostdzire/secrets.yaml.

    The default model uses OpenAI Codex OAuth. Run `bub login openai`
    with CODEX_HOME=${stateDir}/codex for the bub service user before
    expecting model calls to work.
  '';

  users.groups.${user} = { };
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    home = stateDir;
  };

  sops.secrets = lib.mkIf hasBubSecrets {
    "bub/telegram_bot_token" = {
      owner = user;
      group = user;
      restartUnits = [ "bub.service" ];
    };
    "bub/telegram_allow_users" = {
      owner = user;
      group = user;
      restartUnits = [ "bub.service" ];
    };
    "bub/telegram_allow_chats" = {
      owner = user;
      group = user;
      restartUnits = [ "bub.service" ];
    };
  };

  sops.templates."bub-config.yml" = {
    owner = user;
    group = user;
    mode = "0400";
    restartUnits = [ "bub.service" ];
    content = ''
      model: openai:gpt-5.5-codex
      api_format: responses
      max_steps: 50
      max_tokens: 16384
      model_timeout_seconds: 180
      verbose: 1

      enabled_channels: telegram
      stream_output: true
      debounce_seconds: 1
      max_wait_seconds: 10
      active_time_window: 60

      telegram:
        token: ${secretOr "telegram_bot_token" "change-me"}
        allow_users: ${secretOr "telegram_allow_users" ""}
        allow_chats: ${secretOr "telegram_allow_chats" ""}
        proxy: null
    '';
  };

  systemd.services.bub = {
    description = "Bub agent gateway";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "sops-nix.service"
    ];

    environment = {
      BUB_HOME = stateDir;
      BUB_PROJECT = "${stateDir}/bub-project";
      CODEX_HOME = "${stateDir}/codex";
      HOME = stateDir;
      PYTHONUNBUFFERED = "1";
    };

    path = with pkgs; [
      bash
      coreutils
      curl
      git
      gnugrep
      gnused
      gnutar
      gzip
      uv
      xz
    ];

    serviceConfig = {
      User = user;
      Group = user;
      StateDirectory = "bub";
      StateDirectoryMode = "0750";
      WorkingDirectory = stateDir;
      ExecStartPre = "+${
        lib.getExe (
          pkgs.writeShellApplication {
            name = "bub-install-config";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              install -d -m 0750 -o ${user} -g ${user} ${stateDir}/.bub ${stateDir}/workspace ${stateDir}/codex
              ln -sfn ${configTemplate.path} ${stateDir}/.bub/config.yml
              chown -h ${user}:${user} ${stateDir}/.bub/config.yml
            '';
          }
        )
      }";
      ExecStart = "${lib.getExe pkgs.bub} --workspace ${stateDir}/workspace gateway --enable-channel telegram";
      Restart = "always";
      RestartSec = 10;
      TimeoutStopSec = 30;
      KillSignal = "SIGTERM";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ stateDir ];
    };
  };
}
