{ config, secrets, options, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.services.acme;

in
{
  options.modules.services.acme = {
    enable = mkEnableOption "acme";
  };

  config = mkIf cfg.enable {
    security.acme = {
      email = "me@diffumist.me";
      # for test
      # production = false;
      acceptTerms = true;
      certs = {
        "diffumist.me" = {
          credentialsFile = pkgs.writeText "credentials" ''
            CLOUDFLARE_DNS_API_TOKEN=${secrets.cloudflare-token}
          '';
          domain = "*.diffumist.me";
          dnsProvider = "cloudflare";
          extraDomainNames = [
            "diffumist.me"
          ];
        };
      };
    };
  };
}
