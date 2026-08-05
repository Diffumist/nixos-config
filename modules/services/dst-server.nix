{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.dst-server;
  iniFormat = pkgs.formats.ini { };
  luaFormat = pkgs.formats.lua { };

  mkInstance =
    name: instance:
    let
      baseName = "dst-server-${name}";
      targetUnit = "${baseName}.target";
      installUnit = "${baseName}-install.service";
      updateUnit = "${baseName}-update.service";
      prepareUnit = "${baseName}-prepare.service";
      modUpdateUnit = "${baseName}-mod-update.service";
      masterUnit = "${baseName}-master.service";
      cavesUnit = "${baseName}-caves.service";

      stateDirectory = baseName;
      stateDir = "/var/lib/${stateDirectory}";
      installDir = "${stateDir}/install";
      ugcDir = "${stateDir}/ugc";
      clusterId = "Cluster_1";
      clusterDir = "${stateDir}/DoNotStarveTogether/${clusterId}";
      serverBinary = "${installDir}/bin64/dontstarve_dedicated_server_nullrenderer_x64";
      installMarker = "${stateDir}/.install-complete";
      secretName = if name == "main" then "dst_cluster_token" else "dst_cluster_token_${name}";
      tokenFile = config.sops.secrets.${secretName}.path;

      defaultClusterSettings = {
        GAMEPLAY = {
          game_mode = "endless";
          max_players = 6;
          pause_when_empty = true;
          pvp = false;
        };
        MISC.console_enabled = true;
        NETWORK = {
          cluster_description = "Don't Starve Together on NixOS";
          cluster_intention = "social";
          cluster_name = "NixOS DST Server (${name})";
          lan_only_cluster = false;
          offline_cluster = false;
        };
        SHARD.master_port = 10888;
      };
      defaultMasterSettings = {
        ACCOUNT.encode_user_path = true;
        NETWORK.server_port = 10999;
        STEAM = {
          authentication_port = 8766;
          master_server_port = 27016;
        };
      };
      defaultCavesSettings = {
        ACCOUNT.encode_user_path = true;
        NETWORK.server_port = 11000;
        STEAM = {
          authentication_port = 8767;
          master_server_port = 27017;
        };
      };
      defaultMasterWorldgenSettings = {
        overrides = { };
        preset = "SURVIVAL_TOGETHER";
      };
      defaultCavesWorldgenSettings = {
        overrides = { };
        preset = "DST_CAVE";
      };

      clusterSettings =
        lib.recursiveUpdate (lib.recursiveUpdate defaultClusterSettings instance.settings.cluster)
          {
            SHARD = {
              bind_ip = "127.0.0.1";
              cluster_key = "@CLUSTER_KEY@";
              master_ip = "127.0.0.1";
              shard_enabled = true;
            };
          };
      masterSettings =
        lib.recursiveUpdate (lib.recursiveUpdate defaultMasterSettings instance.settings.master)
          { SHARD.is_master = true; };
      cavesSettings =
        lib.recursiveUpdate (lib.recursiveUpdate defaultCavesSettings instance.settings.caves)
          {
            SHARD = {
              is_master = false;
              name = "Caves";
            };
          };
      masterWorldgenSettings =
        lib.recursiveUpdate defaultMasterWorldgenSettings instance.settings.worldgen.master
        // {
          override_enabled = true;
        };
      cavesWorldgenSettings =
        lib.recursiveUpdate defaultCavesWorldgenSettings instance.settings.worldgen.caves
        // {
          override_enabled = true;
        };

      publicPorts = [
        masterSettings.NETWORK.server_port
        cavesSettings.NETWORK.server_port
        masterSettings.STEAM.authentication_port
        cavesSettings.STEAM.authentication_port
        masterSettings.STEAM.master_server_port
        cavesSettings.STEAM.master_server_port
      ];

      clusterIni = iniFormat.generate "${baseName}-cluster.ini" clusterSettings;
      masterIni = iniFormat.generate "${baseName}-master-server.ini" masterSettings;
      cavesIni = iniFormat.generate "${baseName}-caves-server.ini" cavesSettings;
      masterWorldgen = luaFormat.generate "${baseName}-master-worldgenoverride.lua" masterWorldgenSettings;
      cavesWorldgen = luaFormat.generate "${baseName}-caves-worldgenoverride.lua" cavesWorldgenSettings;

      modIds = lib.unique instance.mods;
      modsSetup = pkgs.writeText "${baseName}-dedicated-server-mods-setup.lua" (
        lib.concatMapStringsSep "\n" (id: "ServerModSetup(${builtins.toJSON id})") modIds
        + lib.optionalString (modIds != [ ]) "\n"
      );
      configFiles = [
        clusterIni
        masterIni
        cavesIni
        masterWorldgen
        cavesWorldgen
        modsSetup
      ];

      steamCmd = ''
        ${lib.getExe pkgs.steamcmd} \
          +force_install_dir ${lib.escapeShellArg installDir} \
          +login anonymous \
          +app_update 343050 validate \
          +quit

        test -x ${lib.escapeShellArg serverBinary}
        touch ${lib.escapeShellArg installMarker}
      '';

      commonServiceConfig = {
        User = "dst-server";
        Group = "dst-server";
        StateDirectory = stateDirectory;
        StateDirectoryMode = "0750";
        UMask = "0027";
      };

      mkShardService = shard: {
        description = "Don't Starve Together ${name} ${shard} shard";
        requires = [ modUpdateUnit ] ++ lib.optional (shard == "Caves") masterUnit;
        after = [ modUpdateUnit ] ++ lib.optional (shard == "Caves") masterUnit;
        partOf = [ targetUnit ];
        restartTriggers = configFiles;
        environment = {
          DST_SERVER_ROOT = installDir;
          HOME = stateDir;
        };
        serviceConfig = commonServiceConfig // {
          Type = "simple";
          WorkingDirectory = stateDir;
          ExecStart = ''
            ${lib.getExe pkgs.dst-server-runtime} \
              -skip_update_server_mods \
              -persistent_storage_root ${stateDir} \
              -ugc_directory ${ugcDir} \
              -cluster ${clusterId} \
              -shard ${shard}
          '';
          Restart = "on-failure";
          RestartSec = "10s";
          TimeoutStopSec = "10min";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ stateDir ];
        };
      };
    in
    {
      sopsSecrets.${secretName} = {
        owner = "dst-server";
        group = "dst-server";
        mode = "0400";
        restartUnits = [ targetUnit ];
      };

      inherit publicPorts;

      targets.${baseName} = {
        description = "Don't Starve Together ${name} dedicated server";
        wantedBy = [ "multi-user.target" ];
        wants = [
          masterUnit
          cavesUnit
        ];
      };

      services = {
        "${baseName}-install" = {
          description = "Install the Don't Starve Together ${name} server";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          before = [ prepareUnit ];
          conflicts = [ updateUnit ];
          partOf = [ targetUnit ];
          unitConfig.ConditionPathExists = "!${installMarker}";
          environment.HOME = stateDir;
          serviceConfig = commonServiceConfig // {
            Type = "oneshot";
            RemainAfterExit = true;
            WorkingDirectory = stateDir;
            TimeoutStartSec = "1h";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            ReadWritePaths = [ stateDir ];
          };
          script = steamCmd;
        };

        "${baseName}-update" = {
          description = "Update the Don't Starve Together ${name} server";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          before = [ targetUnit ];
          conflicts = [
            installUnit
            targetUnit
          ];
          environment.HOME = stateDir;
          serviceConfig = commonServiceConfig // {
            Type = "oneshot";
            WorkingDirectory = stateDir;
            TimeoutStartSec = "1h";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            ReadWritePaths = [ stateDir ];
          };
          script = steamCmd;
        };

        "${baseName}-prepare" = {
          description = "Prepare declarative Don't Starve Together ${name} configuration";
          requires = [ installUnit ];
          after = [ installUnit ];
          before = [
            modUpdateUnit
            masterUnit
            cavesUnit
          ];
          partOf = [ targetUnit ];
          restartTriggers = configFiles;
          unitConfig.AssertPathExists = [
            tokenFile
            serverBinary
          ];
          path = [
            pkgs.coreutils
            pkgs.gnused
          ];
          serviceConfig = commonServiceConfig // {
            Type = "oneshot";
            RemainAfterExit = true;
            WorkingDirectory = stateDir;
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            ReadWritePaths = [ stateDir ];
          };
          script = ''
            clusterDir=${lib.escapeShellArg clusterDir}
            clusterKeyFile=${lib.escapeShellArg "${stateDir}/cluster-key"}

            mkdir -p \
              "$clusterDir/Master" \
              "$clusterDir/Caves" \
              ${lib.escapeShellArg "${installDir}/mods"} \
              ${lib.escapeShellArg ugcDir}

            # A local persistent key avoids exposing shard authentication material in the Nix store.
            if [[ ! -s "$clusterKeyFile" ]]; then
              umask 0077
              od -An -N32 -tx1 /dev/urandom | tr -d ' \n' > "$clusterKeyFile.tmp"
              mv -f "$clusterKeyFile.tmp" "$clusterKeyFile"
            fi

            clusterKey="$(<"$clusterKeyFile")"
            sed "s/@CLUSTER_KEY@/$clusterKey/" ${clusterIni} > "$clusterDir/cluster.ini.tmp"
            chmod 0640 "$clusterDir/cluster.ini.tmp"
            mv -f "$clusterDir/cluster.ini.tmp" "$clusterDir/cluster.ini"

            install -Dm0640 ${masterIni} "$clusterDir/Master/server.ini"
            install -Dm0640 ${cavesIni} "$clusterDir/Caves/server.ini"
            install -Dm0640 ${masterWorldgen} "$clusterDir/Master/worldgenoverride.lua"
            install -Dm0640 ${cavesWorldgen} "$clusterDir/Caves/worldgenoverride.lua"
            # Client-generated level data would shadow the declarative dedicated-server overrides.
            rm -f \
              "$clusterDir/Master/leveldataoverride.lua" \
              "$clusterDir/Caves/leveldataoverride.lua"
            install -Dm0644 ${modsSetup} ${lib.escapeShellArg "${installDir}/mods/dedicated_server_mods_setup.lua"}
            ln -sfn ${lib.escapeShellArg tokenFile} "$clusterDir/cluster_token.txt"
          '';
        };

        "${baseName}-mod-update" = {
          description = "Update Don't Starve Together ${name} Workshop mods";
          requires = [ prepareUnit ];
          after = [ prepareUnit ];
          before = [
            masterUnit
            cavesUnit
          ];
          partOf = [ targetUnit ];
          restartTriggers = [ modsSetup ];
          unitConfig.ConditionFileNotEmpty = "${installDir}/mods/dedicated_server_mods_setup.lua";
          environment = {
            DST_SERVER_ROOT = installDir;
            HOME = stateDir;
          };
          serviceConfig = commonServiceConfig // {
            Type = "oneshot";
            RemainAfterExit = true;
            WorkingDirectory = stateDir;
            ExecStart = ''
              ${lib.getExe pkgs.dst-server-runtime} \
                -only_update_server_mods \
                -persistent_storage_root ${stateDir} \
                -ugc_directory ${ugcDir} \
                -cluster ${clusterId} \
                -shard Master
            '';
            TimeoutStartSec = "1h";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            ReadWritePaths = [ stateDir ];
          };
        };

        "${baseName}-master" = mkShardService "Master";
        "${baseName}-caves" = mkShardService "Caves";
      };
    };

  instances = lib.mapAttrsToList mkInstance cfg.instances;
in
{
  options.my.services.dst-server.instances = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          settings = {
            cluster = lib.mkOption {
              type = iniFormat.type;
              default = { };
              description = "Settings merged into cluster.ini.";
            };
            master = lib.mkOption {
              type = iniFormat.type;
              default = { };
              description = "Settings merged into the Master shard server.ini.";
            };
            caves = lib.mkOption {
              type = iniFormat.type;
              default = { };
              description = "Settings merged into the Caves shard server.ini.";
            };
            worldgen = {
              master = lib.mkOption {
                type = luaFormat.type;
                default = { };
                description = "Settings merged into the Master shard worldgenoverride.lua.";
              };
              caves = lib.mkOption {
                type = luaFormat.type;
                default = { };
                description = "Settings merged into the Caves shard worldgenoverride.lua.";
              };
            };
          };

          mods = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Workshop IDs downloaded for this instance.";
          };
        };
      }
    );
    default = { };
    description = "Don't Starve Together server instances.";
  };

  config = {
    users = {
      users.dst-server = lib.mkIf (cfg.instances != { }) {
        isSystemUser = true;
        group = "dst-server";
        description = "Don't Starve Together server user";
      };
      groups.dst-server = lib.mkIf (cfg.instances != { }) { };
    };

    sops.secrets = lib.mergeAttrsList (map (instance: instance.sopsSecrets) instances);
    networking.firewall.allowedUDPPorts = lib.concatMap (instance: instance.publicPorts) instances;
    systemd.targets = lib.mergeAttrsList (map (instance: instance.targets) instances);
    systemd.services = lib.mergeAttrsList (map (instance: instance.services) instances);
  };
}
