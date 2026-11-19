{
  config,
  helpers,
  lib,
  pkgs,
  ...
}:
let
  domain = "ai.503418.xyz";
  oauthHost = "oauth.503418.xyz";
  port = 8317;
  stateDir = "/var/lib/cli-proxy-api";
  runtimeConfig = "${stateDir}/config.yaml";
  managementStaticDir = "${stateDir}/static";
  pluginDir = "${stateDir}/plugins";
in
{
  sops = {
    secrets = {
      "cliproxyapi/config" = {
        owner = "cli-proxy-api";
        group = "cli-proxy-api";
        mode = "0400";
      };
      "cliproxyapi/passwd" = {
        owner = "cli-proxy-api";
        group = "cli-proxy-api";
        mode = "0400";
        restartUnits = [ "cli-proxy-api.service" ];
      };
    };
    templates."cli-proxy-api.env" = {
      owner = "cli-proxy-api";
      group = "cli-proxy-api";
      mode = "0400";
      content = ''
        MANAGEMENT_PASSWORD=${config.sops.placeholder."cliproxyapi/passwd"}
      '';
    };
  };

  users.groups.cli-proxy-api = { };
  users.users.cli-proxy-api = {
    isSystemUser = true;
    group = "cli-proxy-api";
    home = stateDir;
  };

  # OAuth credentials are mutable runtime state and must survive rebuilds.
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 cli-proxy-api cli-proxy-api -"
    "d ${stateDir}/auth 0700 cli-proxy-api cli-proxy-api -"
    "d ${managementStaticDir} 0750 cli-proxy-api cli-proxy-api -"
    "d ${pluginDir} 0750 cli-proxy-api cli-proxy-api -"
  ];

  systemd.services.cli-proxy-api = helpers.systemd.mkService {
    description = "CLIProxyAPI service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "cli-proxy-api";
      Group = "cli-proxy-api";
      WorkingDirectory = stateDir;
      # The management API must write config changes without making SOPS mutable state.
      ExecStartPre = "${pkgs.bash}/bin/bash -eu -c 'if [[ ! -e ${runtimeConfig} ]]; then ${pkgs.coreutils}/bin/install -m 0600 ${
        config.sops.secrets."cliproxyapi/config".path
      } ${runtimeConfig}; fi'";
      ExecStart = "${lib.getExe pkgs.llm-agents.cli-proxy-api} --config ${runtimeConfig}";
      EnvironmentFile = config.sops.templates."cli-proxy-api.env".path;
      Environment = "MANAGEMENT_STATIC_PATH=${managementStaticDir}";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = "cli-proxy-api";
      StateDirectoryMode = "0750";
      UMask = "0077";
    };
  };

  my.services.caddy = {
    enable = true;
    cloudflareOnlyHosts = [ domain ];
    virtualHosts.${domain}.useCloudflareACME = true;
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    @legacyManagement path /management.html
    @managementRoot path /
    @managementApi path /v0/management /v0/management/* /v8/management /v8/management/*
    @api path /v1 /v1/*

    route {
      request_body {
        max_size 128MB
      }

      redir @legacyManagement / 308

      handle @managementRoot {
        import oauth2_forward_auth ${oauthHost}
        reverse_proxy 127.0.0.1:${toString port} {
          rewrite /management.html
        }
      }

      handle @managementApi {
        import oauth2_forward_auth ${oauthHost}
        reverse_proxy 127.0.0.1:${toString port}
      }

      handle @api {
        reverse_proxy 127.0.0.1:${toString port} {
          health_uri /healthz
          health_interval 30s
          health_timeout 5s
        }
      }

      respond 404
    }
  '';
}
