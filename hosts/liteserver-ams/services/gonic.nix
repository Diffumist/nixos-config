{ ... }:
let
  port = 4747;
in
{
  services.gonic = {
    enable = true;
    settings = {
      "listen-addr" = "127.0.0.1:${toString port}";
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

  my.services.caddy = {
    enable = true;
    virtualHosts."music.diffumist.me".useCloudflareACME = true;
  };
  services.caddy.virtualHosts."music.diffumist.me" = {
    extraConfig = ''
      encode zstd gzip

      @admin path /admin /admin/*
      handle @admin {
        forward_auth https://oauth2.diffumist.me {
          uri /oauth2/auth
          copy_headers X-Auth-Request-User X-Auth-Request-Groups X-Auth-Request-Email X-Auth-Request-Preferred-Username
          @error status 401
          handle_response @error {
            redir * https://oauth2.diffumist.me/oauth2/start?rd={scheme}://{host}{uri}
          }
        }
        reverse_proxy 127.0.0.1:${toString port}
      }

      handle {
        reverse_proxy 127.0.0.1:${toString port}
      }
    '';
  };
}
