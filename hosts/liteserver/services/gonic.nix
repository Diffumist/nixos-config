{ config, ... }:
{
  services.gonic = {
    enable = true;
    settings = {
      "listen-addr" = "127.0.0.1:4747";
      "music-path" = [ "/persist/var/storage/music" ];
      "cache-path" = "/persist/var/cache/gonic";
      "db-path" = "/persist/var/lib/gonic/gonic.db";
      "playlists-path" = "/persist/var/lib/gonic/playlists";
      "podcast-path" = "/persist/var/lib/gonic/podcasts";
      "scan-at-start-enabled" = true;
      "scan-watcher-enabled" = true;
      "transcode-cache-size" = 512;
    };
  };

  systemd.services.gonic.serviceConfig = {
    CPUQuota = "100%";
    MemoryMax = "512M";
  };

  systemd.tmpfiles.rules = [
    "d /persist/var/storage/music 0755 root root -"
    "d /persist/var/cache 0755 root root -"
    "d /persist/var/cache/gonic 0750 root root -"
    "d /persist/var/lib/gonic 0750 root root -"
    "d /persist/var/lib/gonic/playlists 0750 root root -"
    "d /persist/var/lib/gonic/podcasts 0750 root root -"
  ];

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."music.diffumist.me" = {
    useACMEHost = "music.diffumist.me";
    extraConfig = ''
      encode zstd gzip

      @admin path /admin /admin/*
      handle @admin {
        forward_auth https://auth.diffumist.me {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }
        reverse_proxy 127.0.0.1:4747
      }

      handle {
        reverse_proxy 127.0.0.1:4747
      }
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."music.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
