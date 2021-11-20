{ config, lib, pkgs, secrets, ... }:

with lib;
with secrets.v2ray;
let
  cfg = config.modules.services.v2ray;
in
{
  options.modules.services.v2ray = {
    enable = mkEnableOption "v2ray";
    port = mkOption {
      default = 47531;
      type = types.port;
    };
    name = mkOption {
      default = "mist";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {

    services = {
      v2ray = {
        enable = true;
        config = {
          log = {
            access = "none";
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
                port = 25;
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
              listen = "127.0.0.1";
              inherit (cfg) port;
              protocol = "vless";
              tag = "vless-in";
              sniffing = {
                enabled = true;
                metadataOnly = false;
              };
              settings = {
                clients = [
                  {
                    inherit id;
                    alterId = 0;
                    email = "me@diffumist.me";
                  }
                ];
                decryption = "none";
              };
              streamSettings = {
                network = "ws";
                security = "none";
                wsSettings = {
                  inherit path;
                  header.Host = "${cfg.name}.${host}";
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

      nginx.virtualHosts."${cfg.name}.${host}" = {
        useACMEHost = config.networking.domain;
        forceSSL = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = 80;
            ssl = false;
          }
        ];
        locations."${path}" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };
  };
}
