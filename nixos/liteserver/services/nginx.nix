{ pkgs, ... }:
{
  services.nginx = {
    enable = true;
    enableReload = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  security.acme = {
    defaults.email = "me@diffumist.me";
    # for test
    # production = false;
    acceptTerms = true;
    certs = {
      "diffumist.me" = {
        credentialsFile = "${pkgs.writeText "credentials" ''

        ''}";
        dnsProvider = "cloudflare";
        extraDomainNames = [
          "*.diffumist.me"
        ];
      };
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];
}
