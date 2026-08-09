{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.caddy;
  cloudflareAccessFile = "${pkgs.cloudflare-ip-ranges}/share/caddy/cloudflare-only.caddy";
  cloudflareTrustedProxiesFile = "${pkgs.cloudflare-ip-ranges}/share/caddy/cloudflare-trusted-proxies.caddy";
  cloudflareACMEHosts = lib.filterAttrs (_: host: host.useCloudflareACME) cfg.virtualHosts;
  oauth2ForwardAuth = authHost: ''
    forward_auth https://${authHost} {
      uri /oauth2/auth
      copy_headers X-Auth-Request-User X-Auth-Request-Groups X-Auth-Request-Email X-Auth-Request-Preferred-Username
      @error status 401
      handle_response @error {
        redir * https://${authHost}/oauth2/start?rd={scheme}://{host}{uri}
      }
    }
  '';
in
{
  options = {
    my.services.caddy = {
      enable = lib.mkEnableOption "the Caddy service";
      cloudflareOnlyHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "app.example.com" ];
        description = ''
          Caddy virtual hosts that only accept HTTP requests whose immediate
          peer is in Cloudflare's published IP ranges.
        '';
      };
      virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              useCloudflareACME = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Provision and use a Cloudflare DNS-01 certificate for this host.";
              };
              oauth2ForwardAuth = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "oauth.example.com";
                description = "OAuth2 Proxy host used to protect the entire virtual host.";
              };
            };
          }
        );
        default = { };
        description = "Shared policy layered onto Caddy virtual hosts.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "services@diffumist.me";
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy-cloudflare;
      globalConfig = ''
        acme_dns cloudflare {env.CF_API_TOKEN}
        servers {
          import ${cloudflareTrustedProxiesFile}
        }
      '';
      virtualHosts = lib.mkMerge [
        (lib.genAttrs cfg.cloudflareOnlyHosts (_: {
          extraConfig = lib.mkBefore ''
            import ${cloudflareAccessFile}
          '';
        }))
        (lib.mapAttrs (
          domain: host:
          lib.optionalAttrs host.useCloudflareACME {
            useACMEHost = domain;
          }
          // lib.optionalAttrs (host.oauth2ForwardAuth != null) {
            extraConfig = lib.mkBefore (oauth2ForwardAuth host.oauth2ForwardAuth);
          }
        ) cfg.virtualHosts)
      ];
    };

    security.acme.certs = lib.mapAttrs (_: _: {
      dnsProvider = "cloudflare";
      credentialFiles = {
        CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
        CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      };
    }) cloudflareACMEHosts;

    systemd.services.caddy.serviceConfig.EnvironmentFile =
      config.sops.templates."caddy-cloudflare.env".path;
    sops.secrets.cloudflare_api_token = {
      sopsFile = ../../profiles/common/secrets/server.yaml;
    };
    sops.templates."caddy-cloudflare.env" = {
      owner = "caddy";
      group = "caddy";
      mode = "0400";
      content = ''
        CF_API_TOKEN=${config.sops.placeholder.cloudflare_api_token}
      '';
    };

    users.users.caddy.extraGroups = [ "acme" ];

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
    };
  };
}
