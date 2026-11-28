{ config, ... }:
let
  domain = "logs.diffumist.dev";
  httpPort = 3100;
  grpcPort = 9095;
  nodes = config.my.services.ranet.nodes;
  data = config.services.loki.dataDir;
in
{
  sops.secrets = {
    "loki_s3/access_key_id" = { };
    "loki_s3/secret_access_key" = { };
    loki_write_passwd_hash = { };
  };
  sops.templates."loki.env" = {
    restartUnits = [ "loki.service" ];
    content = ''
      AWS_ACCESS_KEY_ID=${config.sops.placeholder."loki_s3/access_key_id"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."loki_s3/secret_access_key"}
    '';
  };
  sops.templates."caddy-loki.env" = {
    restartUnits = [ "caddy.service" ];
    content = ''
      LOKI_WRITE_HASH=${config.sops.placeholder.loki_write_passwd_hash}
    '';
  };

  my.systemd.harden = [ "loki" ];
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = httpPort;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = grpcPort;
      };
      common = {
        path_prefix = data;
        replication_factor = 1;
        instance_addr = "127.0.0.1";
        ring.kvstore.store = "inmemory";
      };
      schema_config.configs = [
        {
          from = "2026-01-01";
          store = "tsdb";
          object_store = "s3";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config.aws = {
        endpoint = "https://s3.418.cat";
        region = "garage";
        bucketnames = "fleet-loki";
        s3forcepathstyle = true;
      };
      ingester.wal = {
        dir = "${data}/wal";
        replay_memory_ceiling = "256MB";
      };
      limits_config = {
        max_query_lookback = "720h";
        retention_period = "1440h";
      };
      compactor = {
        working_directory = "${data}/compactor";
        retention_enabled = true;
        delete_request_store = "s3";
      };
      analytics.reporting_enabled = false;
    };
  };
  systemd.services.loki.serviceConfig.EnvironmentFile = config.sops.templates."loki.env".path;
  my.networking.usedTCPPorts = {
    loki = httpPort;
    loki-grpc = grpcPort;
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain} = {
      useCloudflareOriginCert = true;
      cloudflareOnly = true;
      reaction = {
        enable = true;
        name = "loki-caddy";
        methods = [ "POST" ];
        uriRegex = "/loki/api/v1/push";
        statuses = [ 401 ];
        retry = 5;
      };
    };
  };
  services.caddy.environmentFile = config.sops.templates."caddy-loki.env".path;
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    route {
      @push {
        method POST
        path /loki/api/v1/push
      }
      handle @push {
        basic_auth {
          alloy {$LOKI_WRITE_HASH}
        }
        reverse_proxy 127.0.0.1:${toString httpPort}
      }
      @grafana {
        remote_ip ${nodes.hostdzire-sfo.ipv4} ${nodes.hostdzire-sfo.ipv6}
        method GET POST
        path /loki/api/v1/query /loki/api/v1/query_range /loki/api/v1/labels /loki/api/v1/label/*/values /loki/api/v1/series /loki/api/v1/index/* /loki/api/v1/detected_field* /loki/api/v1/detected_labels* /loki/api/v1/patterns /loki/api/v1/tail /loki/api/v1/status/buildinfo
      }
      handle @grafana {
        reverse_proxy 127.0.0.1:${toString httpPort}
      }
      @ready {
        remote_ip 127.0.0.1 ::1
        method GET
        path /ready
      }
      handle @ready {
        reverse_proxy 127.0.0.1:${toString httpPort}
      }
      respond 404
    }
  '';
}
