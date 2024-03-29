{ config, ... }:
{
  sops.secrets = {
    "transmission/username" = {
      owner = config.systemd.services.transmission.serviceConfig.User;
      restartUnits = [ "transmission.service" ];
    };
    "transmission/passwd" = {
      owner = config.systemd.services.transmission.serviceConfig.User;
      restartUnits = [ "transmission.service" ];
    };
  };
  services.transmission = {
    enable = true;
    openRPCPort = true;
    openPeerPorts = true;
    settings = {
      umask = 7; # 660
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
      watch-dir-enabled = true;
      rpc-username = config.sops.secrets."transmission/username".path;
      rpc-password = config.sops.secrets."transmission/passwd".path;
      downloadDirPermissions = "770";
    };
  };

  services.nginx.virtualHosts."bt.diffumist.me" = {
    useACMEHost = config.networking.domain;
    forceSSL = true;
    listen = [
      {
        addr = "0.0.0.0";
        port = 443;
        ssl = true;
      }
    ];
    locations = {
      "/" = {
        proxyPass = "http://localhost:9091/transmission/web";
      };
      "/rpc" = {
        proxyPass = "http://localhost:9091/transmission/rpc";
      };
      "/upload" = {
        proxyPass = "http://localhost:9091/transmission/upload";
      };
    };
  };
}
