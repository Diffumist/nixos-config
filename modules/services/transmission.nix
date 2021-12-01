{ config, options, lib, pkgs, secrets, ... }:

with lib;
let
  cfg = config.modules.transmission;
in
{
  options.modules.transmission = {
    enable = mkEnableOption "transmission";
    rpcPort = mkOption {
      type = types.port;
      default = 9091;
    };
  };
  config = mkIf cfg.enable {
    services.transmission = {
      enable = true;
      openRPCPort = true;
      openPeerPorts = true;
      settings.watch-dir-enabled = true;
      settings.rpc-bind-address = "0.0.0.0";
      settings.download-dir = "/var/lib/transmission/Downloads";
      inherit (secrets.transmission) credentialsFile;
    };

    services.nginx.virtualHosts."vault.diffumist.me" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = 9092;
          ssl = true;
        }
      ];
      locations = {
        "/" = {
          proxyPass = "http://localhost:9091/transmission/web";
          extraConfig = ''
            proxy_set_header X-Real-IP $remote_addr;
            proxy_pass_header X-Transmission-Session-Id;
          '';
        };
        "/rpc" = {
          proxyPass = "http://localhost:9091/transmission/rpc";
        };
        "/upload" = {
          proxyPass = "http://localhost:9091/transmission/upload";
        };
      };
    };

    environment.systemPackages = with pkgs; [ mktorrent ];
  };
}
