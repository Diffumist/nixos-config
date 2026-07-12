{
  config,
  pkgs,
  lib,
  ...
}:
let
  port = 8317;
  domain = "token.diffumist.me";
  stateDir = "/var/lib/cli-proxy-api";
in
{
  users.groups.cli-proxy-api = { };
  users.users.cli-proxy-api = {
    isSystemUser = true;
    group = "cli-proxy-api";
    home = stateDir;
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 cli-proxy-api cli-proxy-api -"
  ];

  systemd.services.cli-proxy-api = {
    description = "CLIProxyAPI service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      ConditionPathExists = "${stateDir}/config.yaml";
    };
    serviceConfig = {
      Type = "simple";
      User = "cli-proxy-api";
      Group = "cli-proxy-api";
      WorkingDirectory = stateDir;
      ExecStart = "${lib.getExe pkgs.llm-agents.cli-proxy-api} --config ${stateDir}/config.yaml";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = "cli-proxy-api";
      StateDirectoryMode = "0750";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ stateDir ];
    };
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."${domain}" = {
    useACMEHost = "${domain}";
    extraConfig = ''
      encode zstd gzip
      request_body {
        max_size 128MB
      }
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."${domain}" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
