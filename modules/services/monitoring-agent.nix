{
  config,
  helpers,
  lib,
  ...
}:
let
  cfg = config.my.services.monitoring-agent;
  nodeExporter = config.my.services.prometheus-node;
  alloyPort = 12345;
  vmagentPort = 8429;
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

    extraScrapeConfigs = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Additional Prometheus scrape_configs appended to vmagent.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."victoriametrics/write_passwd" = {
      sopsFile = ../../profiles/common/secrets/server.yaml;
      restartUnits = [ "vmagent.service" ];
    };

    sops.secrets.loki_write_passwd = {
      sopsFile = ../../profiles/common/secrets/server.yaml;
      restartUnits = [ "alloy.service" ];
    };

    my.systemd.harden = [ "alloy" ];
    services.alloy = {
      enable = true;
      extraFlags = [
        "--disable-reporting"
        "--server.http.listen-addr=127.0.0.1:${toString alloyPort}"
      ];
    };
    systemd.services.alloy.serviceConfig.LoadCredential = [
      "loki-password:${config.sops.secrets.loki_write_passwd.path}"
    ];
    environment.etc."alloy/config.alloy".text = ''
      loki.source.journal "system" {
        labels        = { instance = "${config.networking.hostName}" }
        relabel_rules = loki.relabel.journal.rules
        forward_to    = [loki.write.fleet.receiver]
      }

      loki.relabel "journal" {
        forward_to = []
        rule {
          source_labels = ["__journal__systemd_unit"]
          regex         = "alloy\\.service"
          action        = "drop"
        }
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label  = "level"
        }
      }

      loki.write "fleet" {
        endpoint {
          url = "https://logs.diffumist.dev/loki/api/v1/push"
          basic_auth {
            username      = "alloy"
            password_file = sys.env("CREDENTIALS_DIRECTORY") + "/loki-password"
          }
        }
      }
    '';

    my.services.prometheus-node = {
      enable = true;
      listenAddress = "127.0.0.1";
      openFirewall = false;
    };

    services.vmagent = {
      enable = true;
      openFirewall = false;
      extraArgs = [ "-httpListenAddr=127.0.0.1:${toString vmagentPort}" ];
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
        ]
        ++ cfg.extraScrapeConfigs;
      };
    };

    systemd.services.vmagent = helpers.systemd.mkService {
      wants = [ "prometheus-node-exporter.service" ];
      after = [ "prometheus-node-exporter.service" ];
    };

    my.networking.usedTCPPorts = {
      alloy = alloyPort;
      vmagent = vmagentPort;
    };
  };
}
