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
      ROCKET_LOG = "critical";
      DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
      ENABLE_DB_WAL = false;
      ENABLE_WEBSOCKET = false;
      SHOW_PASSWORD_HINT = false;
    };
  };

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [
      "vaultwarden"
    ];
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.vaultwarden = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  my.services.caddy = {
    enable = true;
    virtualHosts."vault.diffumist.me".useCloudflareACME = true;
  };
  services.caddy.virtualHosts."vault.diffumist.me".extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}
  '';
}
