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

  services.caddy.virtualHosts."immich.diffumist.me" = {
    useACMEHost = "immich.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString config.services.immich.port}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."immich.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
