{ pkgs, config, lib, ... }:

with lib;
let cfg = config.dmist.ss; in
{
  options = {
    dmist.ss = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      ports = mkOption {
        type = types.port;
        default = 53231;
      };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.ss = {
      sopsFile = ./secrets.yaml;
    };

    services.shadowsocks = {
      enable = true;
      port = cfg.ports;
      encryptionMethod = "aes-256-gcm";
      passwordFile = config.sops.secrets.ss.path;
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.ports ];
      allowedUDPPorts = [ cfg.ports ];
    };
  };
}
