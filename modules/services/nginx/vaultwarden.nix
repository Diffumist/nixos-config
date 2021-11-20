{ config, options, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.services.vaultwarden;
in
{
  options.modules.services.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
    backupDir = mkOption {
      type = types.path;
      default = "/persist/private/vaultwarden";
    };
    openPorts = mkOption {
      type = types.port;
      default = 1443;
    };
  };

  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        webVaultEnabled = true;
        websocketEnabled = true;
        signupsVerify = true;
        websocketAddress = "127.0.0.1";
        rocketAddress = "127.0.0.1";
        rocketPort = 3011;
        logFile = "/var/log/bitwarden_rs.log";
        showPasswordHint = false;
      };
      inherit (cfg) backupDir;
    };
    # for backupDir
    system.activationScripts.initVaultwarden = ''
      mkdir -p "${cfg.backupDir}"
      chown "${config.users.users.vaultwarden.name}" "${cfg.backupDir}"
    '';

    services.nginx.virtualHosts."vault.diffumist.me" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = cfg.openPorts;
          ssl = true;
        }
      ];
      locations = {
        "/" = {
          proxyPass = "http://localhost:3011";
          extraConfig = ''
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
        "/notifications/hub" = {
          proxyPass = "http://localhost:3012";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
        "/notifications/hub/negotiate" = {
          proxyPass = "http://localhost:3011";
          extraConfig = ''
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
        "/admin" = {
          proxyPass = "http://localhost:3011";
          extraConfig = ''
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.openPorts ];
    };
  };
}
