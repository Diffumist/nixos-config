{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.postgresql;
in
{
  options = {
    my.services.postgresql = {
      enable = lib.mkEnableOption "The PostgreSQL Service";
      totalRamMB = lib.mkOption {
        type = lib.types.int;
      };
      storageClass = lib.mkOption {
        type = lib.types.enum [
          "ssd"
          "hdd"
        ];
        default = "ssd";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    services.postgresql =
      let
        postgresRamMB = cfg.totalRamMB / 2;
        maxConnections =
          if postgresRamMB <= 2048 then
            80
          else if postgresRamMB <= 8192 then
            120
          else
            200;
        sharedBuffersMB = lib.max 128 (lib.min 8192 (postgresRamMB / 4));
        effectiveCacheMB = lib.max sharedBuffersMB (lib.min (postgresRamMB * 3 / 4) (sharedBuffersMB * 3));
        maintenanceWorkMemMB = lib.max 64 (lib.min 1024 (postgresRamMB / 16));
        autovacuumWorkMemMB = lib.max 64 (lib.min 256 (maintenanceWorkMemMB / 2));
        workMemBudgetMB = lib.max 0 (
          postgresRamMB - sharedBuffersMB - maintenanceWorkMemMB - (autovacuumWorkMemMB * 3) - 512
        );
        workMemMB = lib.max 4 (lib.min 64 (workMemBudgetMB / (maxConnections * 3)));
      in
      {
        enable = true;
        package = pkgs.postgresql_18;

        settings = {
          shared_buffers = "${toString sharedBuffersMB}MB";
          effective_cache_size = "${toString effectiveCacheMB}MB";
          work_mem = "${toString workMemMB}MB";
          maintenance_work_mem = "${toString maintenanceWorkMemMB}MB";
          autovacuum_work_mem = "${toString autovacuumWorkMemMB}MB";
          max_connections = maxConnections;
          min_wal_size = "1GB";
          max_wal_size = "4GB";
          random_page_cost = if (cfg.storageClass or "ssd") == "ssd" then 1.25 else 2.5;
          log_min_duration_statement = 1000;
          log_line_prefix = "%m [%p] %u@%d ";
        };
      };

    services.postgresqlBackup = {
      enable = true;
      backupAll = true;
      compression = "zstd";
    };
  };
}
