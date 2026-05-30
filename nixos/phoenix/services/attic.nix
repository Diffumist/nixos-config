{ config, ... }:
{
  sops.secrets = {
    attic_server_token_rs256_secret_base64 = { };
    cloudflare_api_token = { };
  };

  sops.templates."atticd.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder.attic_server_token_rs256_secret_base64}
    '';
  };

  services.atticd = {
    enable = true;
    mode = "monolithic";
    environmentFile = config.sops.templates."atticd.env".path;
    settings = {
      listen = "127.0.0.1:8080";
      allowed-hosts = [ "attic.diffumist.me" ];
      api-endpoint = "https://attic.diffumist.me/";
    };
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."attic.diffumist.me" = {
    useACMEHost = "attic.diffumist.me";
    extraConfig = ''
      reverse_proxy 127.0.0.1:8080
    '';
  };

  security.acme.certs."attic.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
