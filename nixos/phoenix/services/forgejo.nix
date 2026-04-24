{ config, lib, ... }:
{
  services.forgejo = {
    enable = true;
    lfs.enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    settings = {
      DEFAULT.APP_NAME = "Diffumist's Forgejo";
      server = {
        DOMAIN = "git.diffumist.me";
        ROOT_URL = "https://git.diffumist.me/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
      };
      service.DISABLE_REGISTRATION = false;
      session.COOKIE_SECURE = true;
    };
  };

  my.services.postgresql.enable = true;

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."git.diffumist.me" = {
    useACMEHost = "git.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."git.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
