{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.prometheus-node;
in
{
  options.my.services.prometheus-node = {
    enable = lib.mkEnableOption "Prometheus node exporter";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address for node exporter to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9100;
      description = "Port for node exporter to listen on.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the node exporter port on the host firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      inherit (cfg) listenAddress port openFirewall;
      extraFlags = [
        "--collector.disable-defaults"
        "--collector.cpu"
        "--collector.loadavg"
        "--collector.meminfo"
        "--collector.vmstat"
        "--collector.stat"
        "--collector.filesystem"
        "--collector.diskstats"
        "--collector.netdev"
        "--collector.netstat"
        "--collector.sockstat"
        "--collector.conntrack"
        "--collector.filefd"
        "--collector.time"
        "--collector.uname"
        "--collector.os"
        "--collector.pressure"
        "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|run|var/lib/docker/.+|var/lib/kubelet/.+)($|/)"
        "--collector.diskstats.device-exclude=^(loop|ram|fd|sr|dm-).*"
      ];
    };
  };
}
