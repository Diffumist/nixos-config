{ config, secrets, options, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.acme;

in
{
  options.modules.acme = {
    enable = mkEnableOption "acme";
  };

  config = mkIf cfg.enable {
    security.acme = {
      defaults.email = "me@diffumist.me";
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
        "v2.diffumist.me" = {
          credentialsFile = pkgs.writeText "credentials" ''
            CLOUDFLARE_DNS_API_TOKEN=${secrets.cloudflare-token}
          '';
          domain = "v2.diffumist.me";
          dnsProvider = "cloudflare";
        };
      };
    };
  };
}
