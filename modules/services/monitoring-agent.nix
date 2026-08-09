{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.monitoring-agent;
  nodeExporter = config.my.services.prometheus-node;
in
{
  options.my.services.monitoring-agent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "the node metrics collection agent";
    };

    scrapeInterval = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = "Interval between node exporter scrapes.";
    };

    extraLabels = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        fleet = "vps";
      };
      description = "Additional labels attached to every metric from this host.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."victoriametrics/write_passwd" = {
      sopsFile = ../../profiles/common/secrets/server.yaml;
      restartUnits = [ "vmagent.service" ];
    };

    my.services.prometheus-node = {
      enable = true;
      listenAddress = "127.0.0.1";
      openFirewall = false;
    };

    services.vmagent = {
      enable = true;
      openFirewall = false;
      extraArgs = [ "-httpListenAddr=127.0.0.1:8429" ];
      remoteWrite = {
        url = "https://metrics.diffumist.dev/api/v1/write";
        basicAuthUsername = "vmagent";
        basicAuthPasswordFile = config.sops.secrets."victoriametrics/write_passwd".path;
      };
      prometheusConfig = {
        global = {
          scrape_interval = cfg.scrapeInterval;
          scrape_timeout = "10s";
        };
        scrape_configs = [
          {
            job_name = "integrations/node_exporter";
            static_configs = [
              {
                targets = [ "127.0.0.1:${toString nodeExporter.port}" ];
                labels = cfg.extraLabels // {
                  instance = config.networking.hostName;
                };
              }
            ];
          }
        ];
      };
    };

    systemd.services.vmagent = {
      wants = [ "prometheus-node-exporter.service" ];
      after = [ "prometheus-node-exporter.service" ];
    };
  };
}
