{
  pkgs,
  config,
  helpers,
  hostName,
  hostPath,
  lib,
  ...
}:
let
  cfg = config.my.services.postgresql;
  backupCfg = cfg.backup;
  postgresqlPort = config.services.postgresql.settings.port;
  backupJobNames = [
    "pgbackrest-default-full"
    "pgbackrest-default-diff"
  ];
in
{
  options = {
    my.services.postgresql = {
      enable = lib.mkEnableOption "The PostgreSQL Service" // {
        default = cfg.ensureLocalDatabases != [ ];
        defaultText = lib.literalExpression "config.my.services.postgresql.ensureLocalDatabases != [ ]";
      };
      ensureLocalDatabases = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "grafana" ];
        description = ''
          Local PostgreSQL databases to create alongside a matching role with
          ensureDBOwnership = true. Setting this to a non-empty list enables
          my.services.postgresql by default.
        '';
      };
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
          default = "1ddb57c7f8266ea8489206984571fb77";
          description = "Cloudflare account ID used to build the R2 S3 endpoint.";
        };

        bucket = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "pgbackrest";
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
        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_18;
          ensureDatabases = lib.unique cfg.ensureLocalDatabases;
          ensureUsers = map (name: {
            inherit name;
            ensureDBOwnership = true;
          }) (lib.unique cfg.ensureLocalDatabases);
          settings = helpers.postgresql.mkTuningSettings {
            inherit (cfg) totalRamMB storageClass;
          };
        };

        services.postgresqlBackup = {
          enable = lib.mkDefault (!backupCfg.enable);
          backupAll = true;
          compression = "zstd";
        };

        my.networking.usedTCPPorts = lib.mkIf (config.services.postgresql.settings.listen_addresses != "") {
          postgresql = postgresqlPort;
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
