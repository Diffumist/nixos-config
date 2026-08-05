{
  config,
  lib,
  ...
}:
{

  virtualisation.oci-containers.containers.komari-monitor = {
    image = "ghcr.io/komari-monitor/komari";
    extraOptions = [ "--network=host" ];
    volumes = [ "/var/lib/komari-monitor:/app/data" ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/komari-monitor 0750 root root -"
  ];

  my.services.postgresql.enable = true;
  services.postgresql = {
    authentication = ''
      host komari komari 127.0.0.1/32 trust
      host komari komari ::1/128 trust
    '';
    ensureDatabases = [ "komari" ];
    ensureUsers = [
      {
        name = "komari";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.podman-komari-monitor = {
    after = [
      "postgresql.service"
      "postgresql-setup.service"
      "systemd-tmpfiles-setup.service"
    ];
    requires = [
      "postgresql.service"
      "postgresql-setup.service"
      "systemd-tmpfiles-setup.service"
    ];
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."sla.qzz.io" = {
    useACMEHost = "sla.qzz.io";
    extraConfig = ''
      encode zstd gzip
      request_body {
        max_size 128MB
      }
      reverse_proxy 127.0.0.1:25774
    '';
  };

  security.acme.certs."sla.qzz.io" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
