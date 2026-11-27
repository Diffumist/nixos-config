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

  my.systemd.harden = [ "gonic" ];

  systemd.services.gonic.serviceConfig = {
    CPUQuota = "100%";
    MemoryMax = "512M";
    # Upstream gonic already runs inside RootDirectory=/run/gonic; strict ProtectSystem
    # would make the chroot parent of db-path (/persist/var/lib/gonic) read-only.
    ProtectSystem = false;
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
    virtualHosts."music.diffumist.me" = {
      useCloudflareOriginCert = true;
      cloudflareOnly = true;
    };
  };
  services.caddy.virtualHosts."music.diffumist.me" = {
    extraConfig = ''
      @admin path /admin /admin/*
      handle @admin {
        import oauth2_forward_auth oauth.diffumist.me
        reverse_proxy 127.0.0.1:${toString port}
      }

      handle {
        reverse_proxy 127.0.0.1:${toString port}
      }
    '';
  };

  my.networking.usedTCPPorts.gonic = port;
}
