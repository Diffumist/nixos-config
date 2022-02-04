{ config, lib, pkgs, secrets, ... }: {
  services.telegraf = {
    enable = false;
    environmentFiles = [ secrets.telegraf.envFile ];
    extraConfig = {
      outputs = {
        influxdb_v2 = {
          urls = [ "https://stats-v.diffumist.me" ];
          token = "$INFLUX_TOKEN";
          organization = "diffumist";
          bucket = "diffumist";
        };
      };
      inputs = {
        cpu = { };
        disk = {
          ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "overlay" "aufs" "squashfs" ];
        };
        diskio = { };
        mem = { };
        net = { };
        system = { };
      };
    };
  };
  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = "127.0.0.1:8086";
    };
  };
  services.nginx.virtualHosts."stats-v.diffumist.me" = {
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
        proxyPass = "http://${config.services.influxdb2.settings.http-bind-address}";
        extraConfig = ''
          proxy_set_header X-Real-IP $remote_addr;
        '';
      };
    };
  };
}
