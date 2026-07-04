{ config, ... }:
{
  services.sillytavern = {
    enable = true;
    listen = false;
    listenAddressIPv4 = "127.0.0.1";
    port = 8000;
    whitelist = false;
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."tavern.diffumist.me" = {
    useACMEHost = "tavern.diffumist.me";
    extraConfig = ''
      forward_auth https://auth.diffumist.me {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString config.services.sillytavern.port}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };
  security.acme.certs."tavern.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
