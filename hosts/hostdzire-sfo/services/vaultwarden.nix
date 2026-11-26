{ config, ... }:
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = [ ];
    config = {
      DOMAIN = "https://vault.diffumist.me";
      SIGNUPS_ALLOWED = false;
      DISABLE_ADMIN_TOKEN = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 3011;
      LOG_LEVEL = "warn";
      IP_HEADER = "X-Real-IP";
      DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql&user=vaultwarden";
      ENABLE_DB_WAL = false;
      ENABLE_WEBSOCKET = false;
      SHOW_PASSWORD_HINT = false;
    };
  };

  my.services.postgresql.ensureLocalDatabases = [ "vaultwarden" ];

  my.systemd.harden = [ "vaultwarden" ];
  systemd.services.vaultwarden = {
    confinement = {
      enable = true;
      # EnvironmentFile references the webVault package in the Nix store.
      fullUnit = true;
    };
    serviceConfig.BindPaths = [ "/run/postgresql" ];
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  my.services.caddy = {
    enable = true;
    virtualHosts."vault.diffumist.me".useCloudflareACME = true;
  };
  services.caddy.virtualHosts."vault.diffumist.me".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
      header_up X-Real-IP {client_ip}
    }
  '';

  my.services.reaction.webRules.vaultwarden = {
    unit = "vaultwarden.service";
    regex = [
      ''\[WARN\] Invalid password for '.*' from <ip>\.$''
      ''\[WARN\] Two-factor authentication failed .* from <ip>\.$''
    ];
    retry = 3;
  };

  my.networking.usedTCPPorts.vaultwarden = config.services.vaultwarden.config.ROCKET_PORT;
}
