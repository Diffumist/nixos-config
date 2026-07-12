{ config, ... }:
let
  domain = "uptime.diffumist.me";
  port = "3001";
in
{
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "127.0.0.1";
      PORT = port;
    };
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts.${domain} = {
    useACMEHost = domain;
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${port}
    '';
  };

  security.acme.certs.${domain} = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
