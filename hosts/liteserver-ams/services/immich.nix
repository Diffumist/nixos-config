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

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [
      "immich"
    ];
    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.tmpfiles.rules = [
    "d /persist/var/storage/immich 0700 immich immich -"
  ];

  my.services.caddy = {
    enable = true;
    virtualHosts."immich.diffumist.me".useCloudflareACME = true;
  };
  services.caddy.virtualHosts."immich.diffumist.me".extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:${toString config.services.immich.port}
  '';
}
