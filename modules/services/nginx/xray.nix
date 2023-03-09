{ config, lib, pkgs, secrets, ... }:

with lib;
let
  cfg = config.modules.xray;
in
{
  options.modules.xray = {
    enable = mkEnableOption "xray";
  };

  config = mkIf cfg.enable {

    services = {
      xray = {
        enable = true;
        settings = {
          log = {
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
              port = 4432;
              listen = "127.0.0.1";
              protocol = "vless";
              settings = {
                clients = [
                  {
                    inherit (secrets.v2ray) id;
                    level = 0;
                  }
                ];
                decryption = "none";
              };
              streamSettings = {
                network = "ws";
                security = "none";
                wsSettings = {
                  path = "/r";
                };
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
    services.nginx.virtualHosts."v.diffumist.me" = {
      useACMEHost = "v.diffumist.me";
      forceSSL = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }
      ];
      locations = {
        "/r" = {
          proxyPass = "http://localhost:4432";
          proxyWebsockets = true;
        };
      };
    };
  };
}
