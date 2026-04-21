{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    ensureDatabases = [
      "vaultwarden"
      "memos"
    ];
    # systemctl stop db-services
    # sudo -u postgres dropdb --if-exists db-services
    # systemctl restart postgresql postgresql-setup
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
      {
        name = "memos";
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
