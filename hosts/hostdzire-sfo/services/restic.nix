{ config, ... }:
let
  postgresBackup = config.my.services.postgresql.backup;
  repository = "s3:https://${postgresBackup.accountId}.r2.cloudflarestorage.com/${postgresBackup.bucket}/restic/${config.networking.hostName}/state";
in
{
  assertions = [
    {
      assertion = postgresBackup.enable;
      message = "hostdzire-sfo Restic backups reuse the enabled PostgreSQL R2 repository credentials.";
    }
  ];

  sops = {
    secrets."restic/repository_password" = { };

    # The token is already restricted to the shared R2 backup bucket.
    templates."restic-r2.env" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."pgbackrest/r2_access_key_id"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."pgbackrest/r2_secret_access_key"}
      '';
    };
  };

  services.restic.backups.hostdzire-state = {
    initialize = true;
    inherit repository;
    environmentFile = config.sops.templates."restic-r2.env".path;
    passwordFile = config.sops.secrets."restic/repository_password".path;

    paths = [
      "/var/lib/pocket-id/data/uploads"
      "/var/lib/vaultwarden"
    ];
    exclude = [
      "/var/lib/vaultwarden/icon_cache"
      "/var/lib/vaultwarden/tmp"
    ];

    extraOptions = [
      "s3.bucket-lookup=path"
      "s3.region=auto"
    ];
    extraBackupArgs = [ "--tag=hostdzire-state" ];
    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
      RandomizedDelaySec = "2h";
      FixedRandomDelay = true;
    };
  };
}
