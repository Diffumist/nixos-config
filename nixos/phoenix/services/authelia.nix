{ config, pkgs, ... }:
{

  sops.secrets = {
    authelia_jwt_secret = {
      sopsFile = ./authelia.yaml;
      owner = "authelia-main";
    };
    authelia_storage_encryption_key = {
      sopsFile = ./authelia.yaml;
      owner = "authelia-main";
    };
    authelia_session_secret = {
      sopsFile = ./authelia.yaml;
      owner = "authelia-main";
    };
    authelia_oidc_issuer_private_key = {
      sopsFile = ./authelia.yaml;
      owner = "authelia-main";
    };
    authelia_oidc_hmac_secret = {
      sopsFile = ./authelia.yaml;
      owner = "authelia-main";
    };
    authelia_user_passwd = {
      sopsFile = ./authelia.yaml;
      owner = "authelia-main";
    };
    cloudflare_api_token.sopsFile = ../secrets.yaml;
  };

  sops.templates."users_database.yml" = {
    owner = "authelia-main";
    group = "authelia-main";
    mode = "0400";
    content = ''
      users:
        diffumist:
          displayname: "Diffumist"
          password: "${config.sops.placeholder.authelia_user_passwd}"
          email: "me@diffumist.me"
          groups:
            - admins
    '';
  };
  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
      sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
      oidcIssuerPrivateKeyFile = config.sops.secrets.authelia_oidc_issuer_private_key.path;
      oidcHmacSecretFile = config.sops.secrets.authelia_oidc_hmac_secret.path;
    };
    settings = {
      theme = "dark";
      server = {
        address = "tcp://127.0.0.1:9091/";
      };
      default_2fa_method = "totp";
      log.level = "info";
      authentication_backend.file.path = config.sops.templates."users_database.yml".path;
      storage.postgres = {
        address = "unix:///run/postgresql/.s.PGSQL.5432";
        database = "authelia-main";
        username = "authelia-main";
      };
      session = {
        cookies = [
          {
            domain = "diffumist.me";
            authelia_url = "https://auth.diffumist.me";
            default_redirection_url = "https://auth.diffumist.me";
          }
        ];
      };
      notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "auth.diffumist.me";
            policy = "bypass";
          }
          {
            domain = "code.diffumist.me";
            policy = "one_factor";
          }
        ];
      };
      identity_providers.oidc = {
        clients = [
          {
            client_id = "forgejo";
            client_name = "Forgejo";
            client_secret = "$pbkdf2-sha512$310000$RpxLfGJmW.psLL0y8J4qMg$NOMjBQnqW1jmxB71FuZ0ytID6ewiYWhwmbohvw6GJWPo6IFpLj/.acFu7CEUzXw/1HsZF9muS/1KR22UQwY5cA";
            public = false;
            authorization_policy = "one_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://git.diffumist.me/user/oauth2/authelia/callback"
            ];
            scopes = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];
      };
    };
  };

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [ "authelia-main" ];
    ensureUsers = [
      {
        name = "authelia-main";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.authelia-main = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  # Caddy reverse proxy for Authelia portal
  my.services.caddy.enable = true;
  services.caddy.virtualHosts."auth.diffumist.me" = {
    useACMEHost = "auth.diffumist.me";
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:9091
    '';
  };

  security.acme.certs."auth.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
