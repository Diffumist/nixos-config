{
  config,
  lib,
  pkgs,
  ...
}:
let
  barkDomain = "bark.diffumist.me";
  barkPort = 8090;
  ntfyDomain = "ntfy.diffumist.me";
  ntfyPort = 2586;
  acmeCert = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
in
{
  my.services.caddy.enable = true;

  systemd.services.bark-server = {
    description = "Bark push notification server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "bark-server";
      StateDirectoryMode = "0700";
      ExecStart = "${lib.getExe pkgs.bark-server} --addr 127.0.0.1:${toString barkPort} --data /var/lib/bark-server";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/bark-server" ];
    };
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      web-root = "disable";
      base-url = "https://${ntfyDomain}";
      listen-http = "127.0.0.1:${toString ntfyPort}";
      cache-file = "/var/lib/ntfy-sh/cache.db";
      cache-duration = "24h";
      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      attachment-total-size-limit = "1G";
      attachment-file-size-limit = "15M";
      attachment-expiry-duration = "24h";
      auth-file = "/var/lib/ntfy-sh/auth.db";
      auth-default-access = "deny-all";
      enable-login = true;
      upstream-base-url = "https://ntfy.sh";
      behind-proxy = true;
      proxy-trusted-hosts = "127.0.0.1/8,::1";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/ntfy-sh 0750 ${config.services.ntfy-sh.user} ${config.services.ntfy-sh.group} -"
    "d /var/lib/ntfy-sh/attachments 0750 ${config.services.ntfy-sh.user} ${config.services.ntfy-sh.group} -"
  ];

  services.caddy.virtualHosts = {
    ${barkDomain} = {
      useACMEHost = barkDomain;
      extraConfig = ''
        encode zstd gzip
        reverse_proxy 127.0.0.1:${toString barkPort}
      '';
    };
    ${ntfyDomain} = {
      useACMEHost = ntfyDomain;
      extraConfig = ''
        encode zstd gzip
        reverse_proxy 127.0.0.1:${toString ntfyPort}
      '';
    };
  };

  security.acme.certs = {
    ${barkDomain} = acmeCert;
    ${ntfyDomain} = acmeCert;
  };
}
