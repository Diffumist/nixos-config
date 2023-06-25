{ pkgs, config, ... }:
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
      rpc-host-whitelist-enabled = false;
      watch-dir-enabled = true;
      rpc-username = config.sops.secrets."transmission/username".path;
      rpc-password = config.sops.secrets."transmission/passwd".path;
      downloadDirPermissions = "770";
    };
  };

  services.nginx.virtualHosts."transmission" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 9092;
      }
    ];
    locations = {
      "/rpc" = {
        proxyPass = "http://localhost:9091/transmission/rpc";
      };
      "/upload" = {
        proxyPass = "http://localhost:9091/transmission/upload";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 9092 ];
  environment.systemPackages = with pkgs; [ mktorrent ];
}
