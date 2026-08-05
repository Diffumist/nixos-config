{
  config,
  pkgs,
  ...
}:
let
  domain = "file.diffumist.io";
  port = 5000;
in
{
  sops.secrets.dufs_password = {
    restartUnits = [ "dufs.service" ];
  };
  sops.templates."dufs.env" = {
    mode = "0400";
    content = ''
      DUFS_AUTH=diffumist:${config.sops.placeholder.dufs_password}@/:rw
    '';
  };

  systemd.services.dufs = {
    description = "Dufs file server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      DUFS_SERVE_PATH = "/var/lib/dufs";
      DUFS_BIND = "127.0.0.1";
      DUFS_PORT = toString port;
      DUFS_ALLOW_UPLOAD = "true";
      DUFS_ALLOW_DELETE = "true";
      DUFS_ALLOW_SEARCH = "true";
      DUFS_ALLOW_ARCHIVE = "true";
      DUFS_ALLOW_HASH = "true";
    };
    serviceConfig = {
      ExecStart = "${pkgs.dufs}/bin/dufs";
      EnvironmentFile = config.sops.templates."dufs.env".path;
      DynamicUser = true;
      StateDirectory = "dufs";
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0027";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        # Dufs enumerates local interfaces through getifaddrs() before binding.
        "AF_NETLINK"
      ];
    };
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain}.useCloudflareACME = true;
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
