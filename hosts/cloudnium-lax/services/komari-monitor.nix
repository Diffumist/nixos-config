{
  helpers,
  lib,
  pkgs,
  ...
}:
let
  port = 25774;
in
{
  users = {
    groups.komari-monitor = { };
    users.komari-monitor = {
      isSystemUser = true;
      group = "komari-monitor";
      home = "/var/lib/komari-monitor";
    };
  };

  my.services.postgresql.ensureLocalDatabases = [ "komari" ];
  services.postgresql.authentication = ''
    host komari komari 127.0.0.1/32 trust
    host komari komari ::1/128 trust
  '';

  systemd.services.komari-monitor = helpers.systemd.mkService {
    description = "Komari monitoring server";
    after = [
      "network-online.target"
      "postgresql.service"
      "postgresql-setup.service"
    ];
    wants = [ "network-online.target" ];
    requires = [
      "postgresql.service"
      "postgresql-setup.service"
    ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      GIN_MODE = "release";
      KOMARI_LISTEN = "127.0.0.1:${toString port}";
    };

    serviceConfig = {
      User = "komari-monitor";
      Group = "komari-monitor";
      # StateDirectory migrates the root-owned container state before ExecStart.
      StateDirectory = "komari-monitor";
      StateDirectoryMode = "0750";
      RuntimeDirectory = "komari-monitor";
      WorkingDirectory = "/run/komari-monitor";
      BindPaths = [ "/var/lib/komari-monitor:/run/komari-monitor/data" ];
      ExecStart = "${lib.getExe pkgs.komari-monitor} server";
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0027";
      ReadWritePaths = [ "/var/lib/komari-monitor" ];
    };
  };

  my.services.caddy = {
    enable = true;
    virtualHosts."sla.qzz.io" = {
      useCloudflareACME = true;
      cloudflareOnly = true;
      reaction = {
        enable = true;
        name = "komari-caddy";
        methods = [ "POST" ];
        uriRegex = "/api/login";
        statuses = [
          401
          403
        ];
        retry = 5;
      };
    };
  };
  services.caddy.virtualHosts."sla.qzz.io".extraConfig = ''
    request_body {
      max_size 128MB
    }
    reverse_proxy 127.0.0.1:${toString port}
  '';

  my.networking.usedTCPPorts.komari-monitor = port;
}
