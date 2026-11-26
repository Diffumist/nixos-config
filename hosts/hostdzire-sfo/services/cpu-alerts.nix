{ config, ... }:
{
  my.systemd.harden = [
    "alertmanager"
    "vmalert-fleet"
  ];
  services.vmalert.instances.fleet = {
    enable = true;
    settings = {
      "datasource.url" = "http://127.0.0.1:8428";
      "notifier.url" = [ "http://127.0.0.1:9093" ];
      httpListenAddr = "127.0.0.1:8880";
    };
    rules.groups = [
      {
        name = "fleet-cpu";
        interval = "30s";
        rules = [
          {
            alert = "HostCPUHigh";
            expr = ''
              100 * avg by (instance) (sum without (mode) (
                rate(node_cpu_seconds_total{job="integrations/node_exporter",mode=~"user|nice|system|irq|softirq"}[5m])
              )) > 90
            '';
            for = "10m";
            annotations.summary = ''CPU 执行时间占比 {{ printf "%.1f" $value }}%'';
          }
          {
            alert = "HostCPUStealHigh";
            expr = ''
              100 * avg by (instance) (
                rate(node_cpu_seconds_total{job="integrations/node_exporter",mode="steal"}[5m])
              ) > 10
            '';
            for = "10m";
            annotations.summary = ''CPU steal {{ printf "%.1f" $value }}%'';
          }
        ];
      }
    ];
  };

  sops.secrets.bark_device_key = { };
  sops.templates."alertmanager.env" = {
    restartUnits = [ "alertmanager.service" ];
    content = ''
      BARK_DEVICE_KEY=${config.sops.placeholder.bark_device_key}
    '';
  };
  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    extraFlags = [ "--cluster.listen-address=" ];
    environmentFile = config.sops.templates."alertmanager.env".path;
    configuration = {
      route = {
        receiver = "bark";
        group_by = [
          "instance"
          "alertname"
        ];
      };
      receivers = [
        {
          name = "bark";
          webhook_configs = [
            {
              url = "https://bark.diffumist.me/push";
              send_resolved = true;
              payload = {
                device_key = "$BARK_DEVICE_KEY";
                group = "Fleet CPU";
                title = ''{{ if eq .Status "firing" }}告警{{ else }}恢复{{ end }} · {{ .GroupLabels.instance }}'';
                body = ''{{ .GroupLabels.alertname }}{{ if eq .Status "firing" }} · {{ .CommonAnnotations.summary }}{{ end }}'';
              };
            }
          ];
        }
      ];
    };
  };

  my.networking.usedTCPPorts = {
    vmalert = 8880;
    alertmanager = 9093;
  };
}
