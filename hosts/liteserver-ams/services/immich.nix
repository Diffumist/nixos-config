{ config, ... }:
{
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    mediaLocation = "/persist/var/storage/immich";
    database.createDB = false;
    machine-learning.enable = false;
    settings.server.externalDomain = "https://immich.diffumist.me";
  };

  my.services.postgresql.ensureLocalDatabases = [ "immich" ];

  my.systemd.harden = [
    "immich-server"
    "redis-immich"
  ];
  systemd.services.immich-server.serviceConfig = {
    # Immich runs on Node.js (V8 JIT requires W+X mappings) and reads /proc for CPU topology.
    MemoryDenyWriteExecute = false;
    ProcSubset = "all";
    ReadWritePaths = [ config.services.immich.mediaLocation ];
  };

  systemd.tmpfiles.rules = [
    "d /persist/var/storage/immich 0700 immich immich -"
  ];

  my.services.caddy = {
    enable = true;
    virtualHosts."immich.diffumist.me" = {
      useCloudflareACME = true;
      reaction = {
        enable = true;
        name = "immich-caddy";
        methods = [ "POST" ];
        uriRegex = "/api/auth/login";
        statuses = [
          401
          403
        ];
        retry = 5;
      };
    };
  };
  services.caddy.virtualHosts."immich.diffumist.me".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.immich.port}
  '';

  my.networking.usedTCPPorts.immich = config.services.immich.port;
}
