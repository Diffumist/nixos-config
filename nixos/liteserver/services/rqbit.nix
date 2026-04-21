{ config, ... }:
{
  services.rqbit = {
    enable = true;
    httpHost = "127.0.0.1";
    httpPort = 3030;
    peerPort = 4240;
    openFirewall = true;
    downloadDir = "/persist/var/storage/rqbit";
  };

  services.caddy.virtualHosts."rqbit.diffumist.me" = {
    useACMEHost = "rqbit.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      request_body {
        max_size 128MB
      }
      reverse_proxy 127.0.0.1:3030
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."rqbit.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
