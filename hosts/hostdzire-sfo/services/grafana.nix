{ config, ... }:
let
  grafanaDomain = "grafana.diffumist.dev";
  metricsDomain = "metrics.diffumist.dev";
  grafanaPort = 3000;
  victoriametricsPort = 8428;
in
{
  sops = {
    secrets = {
      "grafana/admin_password" = {
        sopsFile = ./grafana.yaml;
        owner = "grafana";
        group = "grafana";
        restartUnits = [ "grafana.service" ];
      };
      "grafana/secret_key" = {
        sopsFile = ./grafana.yaml;
        owner = "grafana";
        group = "grafana";
        restartUnits = [ "grafana.service" ];
      };
      "victoriametrics/write_passwd_hash" = {
        sopsFile = ./grafana.yaml;
        owner = "caddy";
        group = "caddy";
        restartUnits = [ "caddy.service" ];
      };
    };

    templates."caddy-victoriametrics.env" = {
      owner = "caddy";
      group = "caddy";
      mode = "0400";
      content = ''
        VICTORIAMETRICS_write_passwd_hash=${config.sops.placeholder."victoriametrics/write_passwd_hash"}
      '';
    };
  };

  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:${toString victoriametricsPort}";
    retentionPeriod = "90d";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        protocol = "http";
        http_addr = "127.0.0.1";
        http_port = grafanaPort;
        domain = grafanaDomain;
        root_url = "https://${grafanaDomain}/";
        enforce_domain = true;
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = "grafana";
        user = "grafana";
        ssl_mode = "disable";
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets."grafana/admin_password".path}}";
        secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
        cookie_secure = true;
        disable_gravatar = true;
        strict_transport_security = true;
      };
      users.allow_sign_up = false;
      "auth.anonymous".enabled = false;
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
        feedback_links_enabled = false;
      };
    };
    provision.datasources.settings = {
      apiVersion = 1;
      datasources = [
        {
          name = "VictoriaMetrics";
          uid = "victoriametrics";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString victoriametricsPort}";
          isDefault = true;
          editable = false;
          jsonData = {
            httpMethod = "POST";
            timeInterval = "30s";
          };
        }
      ];
    };
  };

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [ "grafana" ];
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.grafana = {
    requires = [
      "postgresql.service"
      "victoriametrics.service"
    ];
    after = [
      "postgresql.service"
      "victoriametrics.service"
    ];
  };

  my.services.caddy = {
    enable = true;
    virtualHosts = {
      ${grafanaDomain} = {
        useCloudflareACME = true;
        oauth2ForwardAuth = "oauth2.diffumist.dev";
      };
      ${metricsDomain}.useCloudflareACME = true;
    };
  };
  services.caddy = {
    environmentFile = config.sops.templates."caddy-victoriametrics.env".path;
    virtualHosts = {
      ${grafanaDomain} = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy 127.0.0.1:${toString grafanaPort}
        '';
      };
      ${metricsDomain} = {
        extraConfig = ''
          route {
            @remoteWrite {
              method POST
              path /api/v1/write
            }

            handle @remoteWrite {
              basic_auth {
                vmagent {$VICTORIAMETRICS_write_passwd_hash}
              }
              reverse_proxy 127.0.0.1:${toString victoriametricsPort}
            }

            respond 404
          }
        '';
      };
    };
  };
}
