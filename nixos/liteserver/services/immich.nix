{ config, ... }:
{
  services.immich = {
    enable = true;
    mediaLocation = "/persist/var/storage/immich";
    secretsFile = "/run/secrets/immich";
  };
}
