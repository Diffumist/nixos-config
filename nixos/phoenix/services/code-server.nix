{ config, ... }:
{
  services.code-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4444;
    auth = "none";
    user = "forgejo";
    group = "forgejo";
    disableTelemetry = true;
    disableUpdateCheck = true;
    disableWorkspaceTrust = true;
    disableGettingStartedOverride = true;
  };
  systemd.services.code-server.serviceConfig.WorkingDirectory = "/var/lib/forgejo";

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."code.diffumist.me" = {
    useACMEHost = "code.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString config.services.code-server.port}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."code.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
