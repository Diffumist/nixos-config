{
  config,
  secrets,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.acme;

in
{
  options.modules.acme = {
    enable = mkEnableOption "acme";
    domain = mkOption {
      type = types.str;
      default = config.networking.domain;
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      defaults.email = "me@diffumist.me";
      # for test
      # production = false;
      acceptTerms = true;
      certs = {
        "${cfg.domain}" = {
          credentialsFile = "${pkgs.writeText "credentials" ''
            CLOUDFLARE_DNS_API_TOKEN=${secrets.cloudflare-token}
          ''}";
          dnsProvider = "cloudflare";
          extraDomainNames = [
            "*.${cfg.domain}"
          ];
        };
      };
    };

  };
}
