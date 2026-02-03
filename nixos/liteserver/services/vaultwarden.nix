{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
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
    useACMEHost = "diffumist.me";
    forceSSL = true;
    listen = [
      {
        addr = "0.0.0.0";
        port = 443;
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
}
