{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    ensureDatabases = [
      "immich"
    ];
    # systemctl stop db-services
    # sudo -u postgres dropdb --if-exists db-services
    # systemctl restart postgresql postgresql-setup
    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
      }
    ];
    settings = {
      max_connections = "300";
      shared_buffers = "80MB";
    };
  };

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "zstd";
  };
}
