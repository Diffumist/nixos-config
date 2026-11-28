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

    textfiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = "Static Prometheus textfile collector files (keyed by filename without .prom suffix).";
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
      ]
      ++ lib.optionals (cfg.textfiles != { }) [
        "--collector.textfile"
        "--collector.textfile.directory=/etc/prometheus-node-exporter/textfile"
      ];
    };

    environment.etc = lib.mapAttrs' (
      name: text:
      lib.nameValuePair "prometheus-node-exporter/textfile/${name}.prom" {
        inherit text;
      }
    ) cfg.textfiles;

    my.systemd.harden = [ "prometheus-node-exporter" ];
    # Node exporter reads system-wide /proc files (stat, meminfo, net, diskstats, pressure).
    systemd.services.prometheus-node-exporter.serviceConfig = {
      ProcSubset = "all";
    }
    // lib.optionalAttrs (cfg.listenAddress == "127.0.0.1") {
      IPAddressDeny = "any";
      IPAddressAllow = "localhost";
      RestrictAddressFamilies = lib.mkForce [
        "AF_NETLINK"
        "AF_INET"
      ];
    };

    my.networking.usedTCPPorts.prometheus-node-exporter = cfg.port;
  };
}
