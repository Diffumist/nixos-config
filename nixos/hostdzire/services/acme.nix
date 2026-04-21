{ ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "services@diffumist.me";
    # certs."diffumist.me" = {
    #   domain = "*.diffumist.me";
    #   extraDomainNames = [ "diffumist.me" ];
    #   dnsProvider = "cloudflare";
    # credentialFiles = {
    #   CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-api-token.path;
    #   CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare-api-token.path;
    # };
    # };
  };
  services.caddy.enable = true;
  users.users.caddy.extraGroups = [ "acme" ];

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [ 443 ];
  };
}
