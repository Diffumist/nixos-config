{ config, lib, pkgs, secrets, ... }:

with lib;
let
  cfg = config.modules.v2ray;
in
{
  options.modules.v2ray = {
    enable = mkEnableOption "v2ray";
    port = mkOption {
      default = 25433;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {

    services = {
      v2ray = {
        enable = true;
        config = {
          log = {
            access = "/dev/null";
            error = "/dev/null";
            loglevel = "warning";
          };
          routing = {
            domainStrategy = "IPIfNonMatch";
            domainMatcher = "mph";
            rules = [
              {
                type = "field";
                outboundTag = "blocked";
                protocol = [ "bittorrent" ];
              }
              {
                type = "field";
                domain = [
                  "cn"
                ];
                ip = [
                  "geoip:cn"
                  "geoip:private"
                ];
                outboundTag = "blocked";
              }
              {
                type = "field";
                network = "tcp,udp";
                outboundTag = "out";
              }
            ];
          };
          inbounds = [
            {
              port = 10240;
              protocol = "shadowsocks";
              settings = {
                method = "aes-128-gcm";
                ota = true;
                inherit (secrets.v2ray.ss) password;
              };
            }
          ];
          outbounds = [
            {
              protocol = "freedom";
              tag = "out";
            }
            {
              protocol = "blackhole";
              tag = "blocked";
            }
          ];
        };
      };
    };
    networking.firewall = {
      allowedTCPPorts = [ 10240 ];
    };
  };
}
