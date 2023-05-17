{ config, lib, pkgs, secrets, ... }:

with lib;
let
  cfg = config.modules.vaultwarden;
  dbPassword = secrets.vaultwarden.password;
in
{
  options.modules.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
    openPorts = mkOption {
      type = types.port;
      default = 443;
    };
  };

  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      ensureDatabases = [ "bitwarden" ];
      ensureUsers = [{ name = "vaultwarden"; ensurePermissions."DATABASE bitwarden" = "ALL PRIVILEGES"; }];

      initialScript = pkgs.writeText "postgresql-init.sql" ''
        CREATE DATABASE bitwarden;
        CREATE USER vaultwarden WITH PASSWORD '${dbPassword}';
        GRANT ALL PRIVILEGES ON DATABASE bitwarden TO vaultwarden;
      '';
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        signupsAllowed = false;
        webVaultEnabled = true;
        websocketEnabled = true;
        rocketPort = 3011;
        domain = "https://vault.diffumist.me";
        databaseUrl = "postgresql://vaultwarden:${dbPassword}@localhost/bitwarden";
        logFile = "/var/log/bitwarden_rs.log";
        showPasswordHint = false;
      };
    };

    systemd.services.vaultwarden.after = [ "postgresql.service" ];
    services.postgresqlBackup = {
      enable = true;
      databases = [ "bitwarden" ];
    };

    services.nginx.virtualHosts."vault.diffumist.me" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = cfg.openPorts;
          ssl = true;
        }
      ];
      locations = {
        "/" = {
          proxyPass = "http://localhost:3011";
          proxyWebsockets = true;
        };
        "/notifications/hub" = {
          proxyPass = "http://localhost:3012";
          proxyWebsockets = true;
        };
        "/notifications/hub/negotiate" = {
          proxyPass = "http://localhost:3011";
          proxyWebsockets = true;
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.openPorts ];
    };
  };
}
