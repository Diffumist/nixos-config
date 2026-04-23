{ config, ... }:
{
  services.memos = {
    enable = true;
    settings = {
      MEMOS_MODE = "prod";
      MEMOS_ADDR = "127.0.0.1";
      MEMOS_PORT = "5230";
      MEMOS_DATA = config.services.memos.dataDir;
      MEMOS_DRIVER = "postgres";
      MEMOS_DSN = "postgresql:///memos?host=/run/postgresql";
      MEMOS_INSTANCE_URL = "https://memos.diffumist.me";
    };
  };
  systemd.services.memos = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [
      "memos"
    ];
    ensureUsers = [
      {
        name = "memos";
        ensureDBOwnership = true;
      }
    ];
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."memos.diffumist.me" = {
    useACMEHost = "memos.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      request_body {
        max_size 128MB
      }
      reverse_proxy 127.0.0.1:${toString config.services.memos.settings.MEMOS_PORT}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."memos.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
