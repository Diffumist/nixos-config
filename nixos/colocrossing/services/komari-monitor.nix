{
  config,
  lib,
  ...
}:
{

  virtualisation.oci-containers.containers.komari-monitor = {
    image = "ghcr.io/komari-monitor/komari";
    volumes = [ "/var/lib/komari-monitor:/app/data" ];
    ports = [
      "127.0.0.1:25774:25774"
    ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/komari-monitor 0755 root root -"
  ];

  systemd.services.podman-komari-monitor = {
    after = [ "systemd-tmpfiles-setup.service" ];
    requires = [ "systemd-tmpfiles-setup.service" ];
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

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."sla.qzz.io" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
