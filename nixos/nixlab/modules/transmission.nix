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
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
      watch-dir-enabled = true;
      rpc-username = config.sops.secrets."transmission/username".path;
      rpc-password = config.sops.secrets."transmission/passwd".path;
      downloadDirPermissions = "770";
    };
  };
}
