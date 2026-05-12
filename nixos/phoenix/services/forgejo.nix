{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets = {
    cloudflare_api_token.sopsFile = ../secrets.yaml;
    forgejo_client_secret = {
      sopsFile = ./authelia.yaml;
      owner = config.services.forgejo.user;
      group = config.services.forgejo.group;
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
        DISABLE_REGISTRATION = true;
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        SHOW_REGISTRATION_BUTTON = false;
      };
      openid = {
        ENABLE_OPENID_SIGNIN = true;
        ENABLE_OPENID_SIGNUP = false;
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

    path = [
      pkgs.gawk
    ];

    serviceConfig = {
      Type = "oneshot";
      User = config.services.forgejo.user;
      Group = config.services.forgejo.group;
      WorkingDirectory = config.services.forgejo.stateDir;
      RemainAfterExit = true;
    };
    script =
      let
        exe = lib.getExe config.services.forgejo.package;
        appIni = "${config.services.forgejo.customDir}/conf/app.ini";
        workPath = config.services.forgejo.stateDir;
      in
      ''
        set -euo pipefail

        SECRET="$(tr -d '\n' < ${config.sops.secrets.forgejo_client_secret.path})"

        forgejo() {
          ${exe} --config ${lib.escapeShellArg appIni} --work-path ${lib.escapeShellArg workPath} "$@"
        }

        AUTH_ID="$(
          forgejo admin auth list --min-width 0 \
            | awk '$2 == "authelia" { print $1; exit }'
        )"

        if [ -n "$AUTH_ID" ]; then
          forgejo admin auth update-oauth \
            --id="$AUTH_ID" \
            --name=authelia \
            --provider=openidConnect \
            --key=forgejo \
            --secret="$SECRET" \
            --auto-discover-url=https://auth.diffumist.me/.well-known/openid-configuration \
            --scopes=openid \
            --scopes=email \
            --scopes=profile \
            --scopes=groups
        else
          forgejo admin auth add-oauth \
            --name=authelia \
            --provider=openidConnect \
            --key=forgejo \
            --secret="$SECRET" \
            --auto-discover-url=https://auth.diffumist.me/.well-known/openid-configuration \
            --scopes=openid \
            --scopes=email \
            --scopes=profile \
            --scopes=groups
        fi
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
