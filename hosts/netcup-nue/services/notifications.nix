{
  helpers,
  lib,
  pkgs,
  ...
}:
let
  barkDomain = "bark.diffumist.me";
  barkPort = 8090;
  ntfyDomain = "ntfy.diffumist.me";
  ntfyPort = 2586;
in
{
  my.services.caddy = {
    enable = true;
    virtualHosts = {
      ${barkDomain} = {
        useCloudflareOriginCert = true;
        cloudflareOnly = true;
      };
      ${ntfyDomain} = {
        useCloudflareOriginCert = true;
        cloudflareOnly = true;
        reaction = {
          enable = true;
          name = "ntfy-caddy";
          statuses = [
            401
            403
          ];
          retry = 20;
        };
      };
    };
  };
  services.caddy.virtualHosts = {
    ${barkDomain}.extraConfig = ''
      reverse_proxy 127.0.0.1:${toString barkPort}
    '';
    ${ntfyDomain}.extraConfig = ''
      reverse_proxy 127.0.0.1:${toString ntfyPort}
    '';
  };

  systemd.services.bark-server = helpers.systemd.mkService {
    confinement.enable = true;
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

  my.systemd.harden = [ "ntfy-sh" ];
  systemd.services.ntfy-sh.confinement.enable = true;

  my.networking.usedTCPPorts = {
    bark = barkPort;
    ntfy = ntfyPort;
  };
}
