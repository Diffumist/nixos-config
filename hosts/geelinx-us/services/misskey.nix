{ config, ... }:
let
  domain = "mux.im";
  misskeyPort = 3000;
  tuwunelPort = 6167;
in
{
  my.services.caddy.enable = true;

  services.misskey = {
    enable = true;
    database.createLocally = true;
    redis.createLocally = true;
    settings = {
      url = "https://${domain}/";
      port = misskeyPort;
    };
  };

  services.caddy.virtualHosts.${domain} = {
    useACMEHost = domain;
    extraConfig = ''
      encode zstd gzip

      handle /.well-known/matrix/server {
        header Content-Type application/json
        respond `{"m.server":"${domain}:443"}`
      }

      handle /.well-known/matrix/client {
        header Content-Type application/json
        header Access-Control-Allow-Origin "*"
        respond `{"m.homeserver":{"base_url":"https://${domain}"}}`
      }

      handle /_matrix/* {
        reverse_proxy 127.0.0.1:${toString tuwunelPort}
      }

      handle {
        reverse_proxy 127.0.0.1:${toString misskeyPort}
      }
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
