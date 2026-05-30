{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "cybergroupmate";
  stateDir = "/var/lib/cybergroupmate";
  configTemplate = config.sops.templates."cybergroupmate-config.yaml";
  hasCybergroupmateSecrets = lib.hasInfix "cybergroupmate:" (builtins.readFile ../secrets.yaml);
  secretOr =
    name: fallback:
    if hasCybergroupmateSecrets then config.sops.placeholder."cybergroupmate/${name}" else fallback;
in
{
  warnings = lib.optional (!hasCybergroupmateSecrets) ''
    hostdzire CyberGroupmate is using placeholder credentials.
    Add cybergroupmate.gemini_api_key, telegram_bot_token, telegram_api_id,
    telegram_api_hash, and dashboard_token to nixos/hostdzire/secrets.yaml.
  '';

  users.groups.${user} = { };
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    home = stateDir;
  };

  sops.secrets = lib.mkIf hasCybergroupmateSecrets {
    "cybergroupmate/gemini_api_key" = {
      owner = user;
      group = user;
      restartUnits = [ "cybergroupmate.service" ];
    };
    "cybergroupmate/telegram_bot_token" = {
      owner = user;
      group = user;
      restartUnits = [ "cybergroupmate.service" ];
    };
    "cybergroupmate/telegram_api_id" = {
      owner = user;
      group = user;
      restartUnits = [ "cybergroupmate.service" ];
    };
    "cybergroupmate/telegram_api_hash" = {
      owner = user;
      group = user;
      restartUnits = [ "cybergroupmate.service" ];
    };
    "cybergroupmate/dashboard_token" = {
      owner = user;
      group = user;
      restartUnits = [ "cybergroupmate.service" ];
    };
  };

  sops.templates."cybergroupmate-config.yaml" = {
    owner = user;
    group = user;
    mode = "0400";
    restartUnits = [ "cybergroupmate.service" ];
    content = ''
      llm_profiles:
        gemini-flash:
          provider: openai
          base_url: https://generativelanguage.googleapis.com/v1beta/openai/
          api_key: ${secretOr "gemini_api_key" "change-me"}
          model: gemini-3-flash-preview
          temperature: 0.7
          max_tokens: 8192
          max_context_tokens: 200000
          vision: true
          supports_prefill: false
        gemini-pro:
          provider: openai
          base_url: https://generativelanguage.googleapis.com/v1beta/openai/
          api_key: ${secretOr "gemini_api_key" "change-me"}
          model: gemini-3.1-pro-preview
          temperature: 1
          max_tokens: 8192
          max_context_tokens: 500000
          thinking_level: medium
          supports_prefill: false

      llm_routing:
        meta: gemini-flash
        session:
          - gemini-pro
          - gemini-flash
        recording: gemini-flash
        post_task_followup: gemini-flash
        reflection: gemini-flash
        compact: gemini-flash
        memory: gemini-flash
        vision: gemini-flash
        timeouts:
          meta: 120000
          session: 180000
          recording: 120000
          reflection: 180000
          compact: 180000
          memory: 120000
          vision: 120000

      persona:
        name: 赛博群友
        description: |
          你是一个自然、友好、反应灵活的群友。
          你喜欢技术、二次元、游戏和日常闲聊，也会认真回应需要帮助的人。
          你有自己的观点，不需要无脑附和；说话保持轻松、具体、像真人群友。

      timezone: Asia/Shanghai

      notification:
        mention_keywords:
          - 赛博群友
          - "@赛博群友"

      telegram:
        mode: bot
        bot_token: ${secretOr "telegram_bot_token" "change-me"}
        api_id: ${secretOr "telegram_api_id" "0"}
        api_hash: ${secretOr "telegram_api_hash" "change-me"}
        phone: ""
        whitelist:
          enabled: true
          groups: []
          users: []
        humanized_delay:
          enabled: true
          ms_per_char: 45
          min_delay: 500
          max_delay: 5000

      vision:
        attend_mode: describe
        max_image_size: 1024
        max_images_per_context: 3
        sticker_mode: vision_cache
        max_media_download_size: 20
        media_retention_days: 3

      reflection:
        silence_threshold: 7200
        max_interval: 86400
        check_interval: 300
        merge_thresholds:
          episode_to_week: 7
          week_to_month: 30
          month_to_quarter: 90
          quarter_to_year: 365
        tier_limits:
          1:
            max_traits: 10
            max_interests: 15
            episode_days: 14
          2:
            max_traits: 6
            max_interests: 10
            episode_days: 7
          3:
            max_traits: 3
            max_interests: 5
            episode_days: 3
          4:
            max_traits: 1
            max_interests: 2
            episode_days: 1
        awake_hours:
          - 8
          - 24

      context_budget:
        effective_context_window: 200000
        system_prompt_ratio: 0.20
        briefing_ratio: 0.15
        recent_history_ratio: 0.50
        output_reserve: 8192
        min_recent_messages: 8
        max_briefing_tokens: 6000

      embedding:
        provider: local
        dimensions: 128
        similarity_metric: cosine

      dashboard:
        enabled: true
        host: 127.0.0.1
        port: 6767
        token: ${secretOr "dashboard_token" "change-me-local-only"}

      metrics:
        enabled: true
        host: 127.0.0.1
        port: 9092
        path: /metrics

      subagent:
        max_sandbox_instances: 3
        sandbox_idle_timeout: 600000
        poll_interval: 5000
        restrict_adapter_writes_to_bound_chat: true
        deduplicate_sent_messages: true
        post_task_window_ms: 120000
        code_act:
          max_execution_time_ms: 120000
          max_session_messages: 100
          max_turns: 30
        meta_history:
          soft_char_limit: 18000
          trim_target_chars: 10000
          min_messages: 8
          hard_message_limit: 48
          trim_target_messages: 32
        scheduler:
          max_reminders: 10
          max_crons: 10

      recording_pipeline:
        min_flush_size: 10
        normal_threshold: 50
        eager_threshold: 15
        normal_silence_ms: 120000
        eager_silence_ms: 30000
    '';
  };

  systemd.services.cybergroupmate = {
    description = "CyberGroupmate group chat agent";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "sops-nix.service"
    ];

    environment = {
      CYBERGROUPMATE_HOME = stateDir;
      HOME = stateDir;
      NODE_ENV = "production";
      LOG_LEVEL = "info";
    };

    path = with pkgs; [
      bash
      coreutils
      gnugrep
      gnused
      gnutar
      gzip
      xz
    ];

    serviceConfig = {
      User = user;
      Group = user;
      StateDirectory = "cybergroupmate";
      StateDirectoryMode = "0750";
      WorkingDirectory = stateDir;
      ExecStartPre = "+${
        lib.getExe (
          pkgs.writeShellApplication {
            name = "cybergroupmate-install-config";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              install -m 0400 -o ${user} -g ${user} ${configTemplate.path} ${stateDir}/config.yaml
            '';
          }
        )
      }";
      ExecStart = lib.getExe pkgs.cybergroupmate;
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

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."cyber.503418.xyz".extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:6767
  '';

  security.acme.certs."cyber.503418.xyz" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
