{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.vaultwarden;
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
      settings = {
        max_connections = "300";
        shared_buffers = "80MB";
      };
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        domain = "https://vault.diffumist.me";
        signupsAllowed = false;
        rocketPort = 3011;
        databaseUrl = "postgresql://vaultwarden@%2Frun%2Fpostgresql/vaultwarden";
        enableDbWal = "false";
        websocketEnabled = true;
        showPasswordHint = false;
      };
    };

    systemd.services.vaultwarden = {
      requires = [ "postgresql.service" ];
      serviceConfig = {
        EnvironmentFile = "/var/lib/vaultwarden.env";
      };
      after = [ "postgresql.service" ];
    };
    services.postgresqlBackup = {
      enable = true;
      databases = [ "vaultwarden" ];
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
        "/robots.txt" = {
          extraConfig = ''
            rewrite ^/(.*)  $1;
            return 200 "User-agent: *\nDisallow: /";
          '';
        };
      };
    };
  };
}
