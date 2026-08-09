{
  pkgs,
  config,
  hostName,
  hostPath,
  lib,
  ...
}:
let
  cfg = config.my.services.postgresql;
  backupCfg = cfg.backup;
  backupJobNames = [
    "pgbackrest-default-full"
    "pgbackrest-default-diff"
  ];
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
      backup = {
        enable = lib.mkEnableOption "pgBackRest backups to Cloudflare R2";

        accountId = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Cloudflare account ID used to build the R2 S3 endpoint.";
        };

        bucket = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Cloudflare R2 bucket containing this host's pgBackRest repository.";
        };

        repositoryPath = lib.mkOption {
          type = lib.types.strMatching "^/.*";
          default = "/${hostName}";
          description = "Repository prefix inside the R2 bucket.";
        };

        credentialsSopsFile = lib.mkOption {
          type = lib.types.path;
          default = hostPath + "/secrets.yaml";
          defaultText = lib.literalExpression ''hostPath + "/secrets.yaml"'';
          description = "SOPS file containing the pgBackRest R2 credentials and repository cipher passphrase.";
        };

        retentionFull = lib.mkOption {
          type = lib.types.ints.positive;
          default = 2;
          description = "Number of full backups and their dependent backups to retain.";
        };

        retentionDiff = lib.mkOption {
          type = lib.types.ints.positive;
          default = 7;
          description = "Number of differential backups to retain.";
        };

        retentionArchive = lib.mkOption {
          type = lib.types.ints.positive;
          default = 3;
          description = "Number of backup points whose WAL history remains available for PITR.";
        };

        retentionArchiveType = lib.mkOption {
          type = lib.types.enum [
            "full"
            "diff"
            "incr"
          ];
          default = "diff";
          description = "Backup type used to calculate WAL archive retention.";
        };

        fullSchedule = lib.mkOption {
          type = lib.types.str;
          default = "Sun *-*-* 03:00:00";
          description = "systemd calendar expression for full backups.";
        };

        diffSchedule = lib.mkOption {
          type = lib.types.str;
          default = "Mon..Sat *-*-* 03:00:00";
          description = "systemd calendar expression for differential backups.";
        };

        randomizedDelaySec = lib.mkOption {
          type = lib.types.str;
          default = "2h";
          description = "Stable randomized delay applied to backup timers.";
        };
      };
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
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
          enable = lib.mkDefault (!backupCfg.enable);
          backupAll = true;
          compression = "zstd";
        };
      }

      (lib.mkIf backupCfg.enable {
        assertions = [
          {
            assertion = backupCfg.accountId != null && backupCfg.accountId != "";
            message = "my.services.postgresql.backup.accountId must be set when pgBackRest backups are enabled.";
          }
          {
            assertion = backupCfg.bucket != null && backupCfg.bucket != "";
            message = "my.services.postgresql.backup.bucket must be set when pgBackRest backups are enabled.";
          }
        ];

        sops.secrets = {
          "pgbackrest/r2_access_key_id".sopsFile = backupCfg.credentialsSopsFile;
          "pgbackrest/r2_secret_access_key".sopsFile = backupCfg.credentialsSopsFile;
          "pgbackrest/repository_cipher_passphrase".sopsFile = backupCfg.credentialsSopsFile;
        };

        # pgBackRest loads *.conf from this directory while keeping secrets out of the Nix store.
        sops.templates."pgbackrest-r2.conf" = {
          path = "/etc/pgbackrest/conf.d/r2.conf";
          owner = "postgres";
          group = "postgres";
          mode = "0400";
          content = ''
            [global]
            repo1-cipher-pass=${config.sops.placeholder."pgbackrest/repository_cipher_passphrase"}
            repo1-s3-key=${config.sops.placeholder."pgbackrest/r2_access_key_id"}
            repo1-s3-key-secret=${config.sops.placeholder."pgbackrest/r2_secret_access_key"}
          '';
        };

        services.pgbackrest = {
          enable = true;
          settings = {
            compress-type = "zst";
            process-max = 2;
            start-fast = true;
          };
          repos.localhost = {
            type = "s3";
            path = backupCfg.repositoryPath;
            bundle = true;
            block = true;
            cipher-type = "aes-256-cbc";
            retention-full = backupCfg.retentionFull;
            retention-diff = backupCfg.retentionDiff;
            retention-archive = backupCfg.retentionArchive;
            retention-archive-type = backupCfg.retentionArchiveType;
            s3-bucket = backupCfg.bucket;
            s3-endpoint = "${backupCfg.accountId}.r2.cloudflarestorage.com";
            s3-region = "auto";
            s3-uri-style = "path";
          };
          stanzas.default.jobs = {
            full = {
              type = "full";
              schedule = backupCfg.fullSchedule;
            };
            diff = {
              type = "diff";
              schedule = backupCfg.diffSchedule;
            };
          };
        };

        # Low-write databases still need WAL segments closed often enough to bound the PITR RPO.
        services.postgresql.settings.archive_timeout = 15 * 60;

        # The NixOS module otherwise reuses the remote repository prefix as a local home path.
        users.users.pgbackrest.home = lib.mkForce "/var/lib/pgbackrest";

        # Existing clusters may not have been initialized with group-readable PGDATA.
        systemd.services = lib.genAttrs backupJobNames (_: {
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          unitConfig.AssertPathExists = config.sops.templates."pgbackrest-r2.conf".path;
          serviceConfig = {
            User = lib.mkForce "postgres";
            Group = lib.mkForce "postgres";
          };
        });

        systemd.timers = lib.genAttrs backupJobNames (_: {
          timerConfig = {
            RandomizedDelaySec = backupCfg.randomizedDelaySec;
            FixedRandomDelay = true;
          };
        });
      })
    ]
  );
}
