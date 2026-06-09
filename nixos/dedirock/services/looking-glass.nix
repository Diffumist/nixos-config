{ config, ... }:
let
  domain = "lg.diffumist.me";
  frontendPort = 5000;
  proxyPort = 8000;
in
{
  services.bird-lg.frontend = {
    enable = true;
    listenAddresses = "127.0.0.1:${toString frontendPort}";
    proxyPort = proxyPort;
    servers = [
      "AMS-0<ams-0.lg>"
      "SJC-0<sjc-0.lg>"
      "LAX-0<lax-0.lg>"
      "TYO-0<tyo-0.lg>"
      "IX-VM-2465<ix-vm.lg>"
    ];
    domain = "";
    netSpecificMode = "dn42";
    protocolFilter = [ "BGP" ];
    titleBrand = "Diffumist's DN42 Looking Glass";
    navbar.brand = "Diffumist's DN42 LG";
  };

  networking.hosts = {
    "172.22.64.65" = [ "ams-0.lg" ];
    "172.22.64.66" = [ "sjc-0.lg" ];
    "172.22.64.67" = [ "lax-0.lg" ];
    "172.22.64.68" = [ "tyo-0.lg" ];
    "242.99.55.190" = [ "ix-vm.lg" ];
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts.${domain} = {
    useACMEHost = domain;
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString frontendPort}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs.${domain} = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
