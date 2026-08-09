{ config, lib, ... }:
let
  pocketIdDomain = "id.418.cat";
  port = 4180;
  authDomains = [
    "oauth.diffumist.me"
    "oauth.diffumist.dev"
    "oauth.diffumist.io"
    "oauth.diffumist.moe"
    "oauth.503418.xyz"
    "oauth.418.cat"
    "oauth.mux.im"
  ];
  cookieDomains = [
    ".diffumist.me"
    ".diffumist.dev"
    ".diffumist.io"
    ".diffumist.moe"
    ".503418.xyz"
    ".418.cat"
    ".mux.im"
  ];
in
{
  sops.secrets = {
    "oauth2-proxy/pocketid_client_secret" = {
      sopsFile = ./oauth2.yaml;
      owner = "oauth2-proxy";
      group = "oauth2-proxy";
      restartUnits = [ "oauth2-proxy.service" ];
    };
    "oauth2-proxy/cookie_secret" = {
      sopsFile = ./oauth2.yaml;
      owner = "oauth2-proxy";
      group = "oauth2-proxy";
      restartUnits = [ "oauth2-proxy.service" ];
    };
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    clientID = "tinyauth";
    clientSecretFile = config.sops.secrets."oauth2-proxy/pocketid_client_secret".path;
    oidcIssuerUrl = "https://${pocketIdDomain}";
    scope = "openid profile email groups";
    email.domains = [ "*" ];

    httpAddress = "http://127.0.0.1:${toString port}";
    reverseProxy = true;
    trustedProxyIP = [
      "127.0.0.1/32"
      "::1/128"
    ];
    setXauthrequest = true;
    upstream = [ "static://202" ];

    cookie.secretFile = config.sops.secrets."oauth2-proxy/cookie_secret".path;
    extraConfig = {
      "cookie-domain" = cookieDomains;
      "whitelist-domain" = cookieDomains;
      "code-challenge-method" = "S256";
      "insecure-oidc-allow-unverified-email" = true;
      "provider-display-name" = "Pocket ID";
      "skip-provider-button" = true;
    };
  };

  systemd.services.oauth2-proxy = {
    requires = [ "pocket-id.service" ];
    after = [ "pocket-id.service" ];
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts = lib.genAttrs authDomains (domain: {
    useACMEHost = domain;
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port} {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Uri {uri}
      }
    '';
  });

  security.acme.certs = lib.genAttrs authDomains (_: {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  });
}
