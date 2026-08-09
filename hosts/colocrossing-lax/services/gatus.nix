{ config, lib, ... }:
let
  domain = "status.diffumist.dev";
  port = 8080;
  certificateWarningThreshold = "336h";
  mkHttpsEndpoint =
    {
      name,
      group,
      url,
      statusConditions ? [ "[STATUS] == 200" ],
      responseTimeLimit ? 5000,
      ignoreRedirect ? false,
    }:
    {
      inherit name group url;
      interval = "1m";
      ui = {
        hide-url = true;
        hide-hostname = true;
        hide-errors = true;
      };
      conditions = statusConditions ++ [
        "[RESPONSE_TIME] < ${toString responseTimeLimit}"
        "[CERTIFICATE_EXPIRATION] > ${certificateWarningThreshold}"
      ];
    }
    // lib.optionalAttrs ignoreRedirect {
      client.ignore-redirect = true;
    };
in
{
  services.gatus = {
    enable = true;
    settings = {
      web = {
        address = "127.0.0.1";
        inherit port;
      };
      ui = {
        title = "Diffumist's Service Status";
        header = "Diffumist's Service Status";
        dashboard-heading = "Service Health";
        dashboard-subheading = "Live availability and response time";
        default-sort-by = "group";
      };
      storage = {
        type = "postgres";
        path = "postgresql:///gatus?host=/run/postgresql&user=gatus&sslmode=disable";
        maximum-number-of-results = 1440;
        maximum-number-of-events = 100;
      };
      metrics = true;
      endpoints = map mkHttpsEndpoint [
        {
          name = "Komari";
          group = "Monitoring";
          url = "https://sla.qzz.io";
        }
        {
          name = "Grafana";
          group = "Monitoring";
          url = "https://grafana.diffumist.dev";
          statusConditions = [ "[STATUS] == 302" ];
          ignoreRedirect = true;
        }
        {
          name = "Pocket ID";
          group = "Identity";
          url = "https://id.418.cat/healthz";
          statusConditions = [ "[STATUS] == 204" ];
        }
        {
          name = "OAuth";
          group = "Identity";
          url = "https://oauth.diffumist.me/ready";
        }
        {
          name = "TGTLDR";
          group = "Applications";
          url = "https://tg.503418.xyz";
        }
        {
          name = "Vaultwarden";
          group = "Identity";
          url = "https://vault.diffumist.me/alive";
        }
        {
          name = "Misskey";
          group = "Applications";
          url = "https://mux.im";
        }
        {
          name = "Matrix";
          group = "Applications";
          url = "https://mux.im/_matrix/client/versions";
        }
        {
          name = "SillyTavern";
          group = "Applications";
          url = "https://tavern.diffumist.me";
          statusConditions = [ "[STATUS] == 302" ];
          ignoreRedirect = true;
        }
        {
          name = "Pastebin";
          group = "Applications";
          url = "https://nixos.bond";
        }
        {
          name = "418.cat";
          group = "Applications";
          url = "https://418.cat";
        }
        {
          name = "Transmission";
          group = "Media";
          url = "https://bt.503418.xyz/transmission/rpc";
          statusConditions = [ "[STATUS] == 401" ];
        }
        {
          name = "PowerDNS API";
          group = "DN42";
          url = "https://zones.diffumist.me/api/v1/servers/localhost";
          statusConditions = [ "[STATUS] == 401" ];
        }
        {
          name = "Dufs";
          group = "Infrastructure";
          url = "https://file.diffumist.io";
          statusConditions = [ "[STATUS] == 401" ];
        }
        {
          name = "Attic";
          group = "Infrastructure";
          url = "https://attic.diffumist.me";
        }
        {
          name = "Forgejo";
          group = "Infrastructure";
          url = "https://git.418.cat/api/healthz";
        }
        {
          name = "Garage UI";
          group = "Infrastructure";
          url = "https://s3-ui.418.cat/health";
        }
        {
          name = "Garage S3";
          group = "Infrastructure";
          url = "https://s3.418.cat";
          statusConditions = [ "[STATUS] == 403" ];
        }
        {
          name = "Bark";
          group = "Notifications";
          url = "https://bark.diffumist.me/healthz";
        }
        {
          name = "ntfy";
          group = "Notifications";
          url = "https://ntfy.diffumist.me/v1/health";
        }
        {
          name = "Immich";
          group = "Media";
          url = "https://immich.diffumist.me/api/server/ping";
        }
        {
          name = "Gonic";
          group = "Media";
          url = "https://music.diffumist.me";
          statusConditions = [ "[STATUS] == 303" ];
          ignoreRedirect = true;
        }
        {
          name = "Looking Glass";
          group = "DN42";
          url = "https://lg-dn42.diffumist.me";
          responseTimeLimit = 10000;
        }
        {
          name = "Flap Damping";
          group = "DN42";
          url = "https://flap-dn42.diffumist.me";
        }
      ];
    };
  };

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [ "gatus" ];
    ensureUsers = [
      {
        name = "gatus";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.gatus = {
    after = [
      "postgresql.service"
      "postgresql-setup.service"
    ];
    requires = [
      "postgresql.service"
      "postgresql-setup.service"
    ];
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain}.useCloudflareACME = true;
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:${toString port}
  '';

  services.vmagent.prometheusConfig.scrape_configs = [
    {
      job_name = "integrations/gatus";
      static_configs = [
        {
          targets = [ "127.0.0.1:${toString port}" ];
          labels.instance = config.networking.hostName;
        }
      ];
    }
  ];
}
