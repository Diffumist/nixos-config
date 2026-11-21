{ config, lib, ... }:
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
      DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
      ENABLE_DB_WAL = false;
      ENABLE_WEBSOCKET = false;
      SHOW_PASSWORD_HINT = false;
    };
  };

  my.services.postgresql.ensureLocalDatabases = [ "vaultwarden" ];

  systemd.services.vaultwarden = {
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

  services.fail2ban.jails.vaultwarden = lib.mkIf config.services.fail2ban.enable {
    settings = {
      enabled = true;
      filter = "vaultwarden";
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=vaultwarden.service";
      port = "80,443";
      protocol = "tcp,udp";
      maxretry = 3;
      bantime = "24h";
    };
  };

  environment.etc."fail2ban/filter.d/vaultwarden.local" = lib.mkIf config.services.fail2ban.enable {
    text = ''
      [Definition]
      failregex = ^.*\[WARN\] Invalid password for '.*' from <HOST>\.$
                  ^.*\[WARN\] Two-factor authentication failed .* from <HOST>\.$
    '';
  };

  my.networking.usedTCPPorts.vaultwarden = config.services.vaultwarden.config.ROCKET_PORT;
}
