{ config, ... }:
let
  port = 8080;
in
{
  sops.secrets = {
    attic_server_token_rs256_secret_base64 = { };
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
      listen = "127.0.0.1:${toString port}";
      allowed-hosts = [ "attic.diffumist.me" ];
      api-endpoint = "https://attic.diffumist.me/";
    };
  };

  my.systemd.harden = [ "atticd" ];
  systemd.services.atticd.confinement.enable = true;

  my.services.caddy = {
    enable = true;
    virtualHosts."attic.diffumist.me".fail2ban = {
      enable = true;
      name = "attic-caddy";
      statuses = [
        401
        403
      ];
      maxretry = 6;
    };
  };
  services.caddy.virtualHosts."attic.diffumist.me" = {
    useACMEHost = "attic.diffumist.me";
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };

  security.acme.certs."attic.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };

  my.networking.usedTCPPorts.atticd = port;
}
