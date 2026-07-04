{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.sema;
  settingsFormat = pkgs.formats.toml { };
  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      settingsFormat.generate "sema.toml" (if cfg.settings != null then cfg.settings else { });
in
{
  options.my.services.sema = {
    enable = lib.mkEnableOption "sema dead man's switch service";

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "config.sops.secrets.sema_config.path";
      description = "Runtime TOML config file for sema. Use this for secret-bearing configs.";
    };

    settings = lib.mkOption {
      type = lib.types.nullOr settingsFormat.type;
      default = null;
      example = {
        bind_addr = "127.0.0.1:8080";
        scan_interval_seconds = 30;
        state_path = "sema-state.json";
        checks = [
          {
            id = "backup";
            token = "replace-with-a-long-random-token";
            period_seconds = 60;
            grace_seconds = 180;
          }
        ];
      };
      description = "sema TOML config as Nix attrs. Values are written to the Nix store.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the sema HTTP port on the host firewall.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Firewall port to open when openFirewall is enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != null || cfg.settings != null;
        message = "my.services.sema requires either configFile or settings.";
      }
      {
        assertion = cfg.configFile == null || cfg.settings == null;
        message = "my.services.sema configFile and settings are mutually exclusive.";
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    users = {
      users.sema = {
        isSystemUser = true;
        group = "sema";
        home = "/var/lib/sema";
      };
      groups.sema = { };
    };

    systemd.services.sema = {
      description = "sema dead man's switch webhook server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.AssertPathExists = configFile;
      serviceConfig = {
        User = "sema";
        Group = "sema";
        StateDirectory = "sema";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/sema";
        ExecStart = "${lib.getExe pkgs.sema} --config ${configFile}";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };
  };
}
