{ config, ... }:
let
  domain = "bt.503418.xyz";
  downloadDir = "/persist/var/storage/transmission";
  peerPort = 4240;
  rpcPort = 9091;
in
{
  sops.secrets.transmission_rpc_password = {
    sopsFile = ./transmission.yaml;
    restartUnits = [ "transmission.service" ];
  };
  sops.templates."transmission-credentials.json" = {
    owner = "transmission";
    group = "transmission";
    mode = "0400";
    content = builtins.toJSON {
      "rpc-password" = config.sops.placeholder.transmission_rpc_password;
    };
  };

  services.transmission = {
    enable = true;
    openPeerPorts = true;
    downloadDirPermissions = "0770";
    credentialsFile = config.sops.templates."transmission-credentials.json".path;
    settings = {
      "download-dir" = downloadDir;
      "incomplete-dir" = "${downloadDir}/.incomplete";
      "incomplete-dir-enabled" = true;
      "peer-port" = peerPort;
      "peer-port-random-on-start" = false;
      "rpc-authentication-required" = true;
      "rpc-bind-address" = "127.0.0.1";
      "rpc-host-whitelist" = domain;
      "rpc-host-whitelist-enabled" = true;
      "rpc-port" = rpcPort;
      "rpc-url" = "/transmission/";
      "rpc-username" = "diffumist";
      "rpc-whitelist" = "127.0.0.1,::1";
      "rpc-whitelist-enabled" = true;
      umask = "002";
    };
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain} = {
      useCloudflareACME = true;
      fail2ban = {
        enable = true;
        name = "transmission-caddy";
        statuses = [ 401 ];
        maxretry = 5;
      };
    };
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    @root path /
    redir @root /transmission/web/ 302
    reverse_proxy 127.0.0.1:${toString rpcPort}
  '';

  my.networking = {
    usedTCPPorts = {
      transmission-peer = peerPort;
      transmission-rpc = rpcPort;
    };
    usedUDPPorts.transmission-peer = peerPort;
  };
}
