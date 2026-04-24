{ config, lib, ... }:
{
  sops.secrets = {
    cloudflare_api_token.sopsFile = ../secrets.yaml;
    authelia_client_secret = {
      sopsFile = ./authelia.yaml;
      owner = "forgejo";
    };
  };

  services.forgejo = {
    enable = true;
    lfs.enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    settings = {
      DEFAULT.APP_NAME = "Diffumist's Forgejo";
      server = {
        DOMAIN = "git.diffumist.me";
        ROOT_URL = "https://git.diffumist.me/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
      };
      service = {
        DISABLE_REGISTRATION = false;
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        SHOW_REGISTRATION_BUTTON = false;
      };
      openid = {
        ENABLE_OPENID_SIGNIN = false;
        ENABLE_OPENID_SIGNUP = true;
        WHITELISTED_URIS = "auth.diffumist.me";
      };
      session.COOKIE_SECURE = true;
    };
  };

  my.services.postgresql.enable = true;

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."git.diffumist.me" = {
    useACMEHost = "git.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}
    '';
  };

  # Auto-register Authelia as OAuth2 authentication source
  systemd.services.forgejo-authelia-oauth = {
    description = "Register Authelia OAuth2 source in Forgejo";
    requires = [ "forgejo.service" ];
    after = [ "forgejo.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "forgejo";
      Group = "forgejo";
      RemainAfterExit = true;
    };
    script =
      let
        exe = lib.getExe config.services.forgejo.package;
      in
      ''
        SECRET="$(cat ${config.sops.secrets.authelia_client_secret.path})"

        ${exe} admin auth update-oauth \
          --name=authelia \
          --provider=openidConnect \
          --key=forgejo \
          --secret="$SECRET" \
          --auto-discover-url=https://auth.diffumist.me/.well-known/openid-configuration \
          --scopes='openid email profile groups' \
        || ${exe} admin auth add-oauth \
          --name=authelia \
          --provider=openidConnect \
          --key=forgejo \
          --secret="$SECRET" \
          --auto-discover-url=https://auth.diffumist.me/.well-known/openid-configuration \
          --scopes='openid email profile groups'
      '';
  };

  security.acme.certs."git.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
