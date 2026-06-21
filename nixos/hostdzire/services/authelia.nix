{ config, pkgs, ... }:
{

  sops.secrets = {
    "authelia/jwt_secret" = {
      owner = config.services.authelia.instances.main.user;
      group = config.services.authelia.instances.main.group;
      restartUnits = [ "authelia-main.service" ];
    };
    "authelia/storage_encryption_key" = {
      owner = config.services.authelia.instances.main.user;
      group = config.services.authelia.instances.main.group;
      restartUnits = [ "authelia-main.service" ];
    };
    "authelia/session_secret" = {
      owner = config.services.authelia.instances.main.user;
      group = config.services.authelia.instances.main.group;
      restartUnits = [ "authelia-main.service" ];
    };
    "authelia/client_secret" = {
      owner = config.services.authelia.instances.main.user;
      group = config.services.authelia.instances.main.group;
      restartUnits = [ "authelia-main.service" ];
    };
    "authelia/oidc_issuer_private_key" = {
      owner = config.services.authelia.instances.main.user;
      group = config.services.authelia.instances.main.group;
      restartUnits = [ "authelia-main.service" ];
    };
    "authelia/oidc_hmac_secret" = {
      owner = config.services.authelia.instances.main.user;
      group = config.services.authelia.instances.main.group;
      restartUnits = [ "authelia-main.service" ];
    };
    "authelia/lldap_passwd" = {
      owner = config.services.authelia.instances.main.user;
      group = config.services.authelia.instances.main.group;
      restartUnits = [ "authelia-main.service" ];
    };
  };
  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia/storage_encryption_key".path;
      sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."authelia/oidc_issuer_private_key".path;
      oidcHmacSecretFile = config.sops.secrets."authelia/oidc_hmac_secret".path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
        config.sops.secrets."authelia/lldap_passwd".path;
    };
    settings = {
      theme = "dark";
      server = {
        address = "tcp://127.0.0.1:9091/";
      };
      default_2fa_method = "webauthn";
      totp.disable = true;
      log.level = "info";
      authentication_backend = {
        refresh_interval = "1m";
        password_reset.disable = true;
        password_change.disable = true;
        ldap = {
          implementation = "lldap";
          address = "ldap://127.0.0.1:3890";
          base_dn = "dc=diffumist,dc=me";
          user = "uid=authelia,ou=people,dc=diffumist,dc=me";
        };
      };
      storage.postgres = {
        address = "unix:///run/postgresql";
        database = "authelia-main";
        username = "authelia-main";
      };
      session = {
        cookies = [
          {
            domain = "diffumist.me";
            authelia_url = "https://auth.diffumist.me";
          }
        ];
      };
      webauthn = {
        disable = false;
        enable_passkey_login = false;
        display_name = "Diffumist's Authelia";
        attestation_conveyance_preference = "indirect";
        timeout = "60 seconds";
        selection_criteria = {
          attachment = "";
          discoverability = "preferred";
          user_verification = "preferred";
        };
        metadata.enabled = false;
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
            domain = [
              "git.diffumist.me"
              "hermes.diffumist.me"
              "music.diffumist.me"
              "tavern.diffumist.me"
            ];
            policy = "two_factor";
          }
        ];
      };
      identity_providers.oidc = {
        clients = [
          {
            client_id = "forgejo";
            client_name = "Forgejo";
            client_secret = "{{ fileContent \"${config.sops.secrets."authelia/client_secret".path}\" | trim }}";
            public = false;
            authorization_policy = "two_factor";
            require_pkce = false;
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
            token_endpoint_auth_method = "client_secret_post";
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
    requires = [
      "lldap.service"
      "postgresql.service"
    ];
    after = [
      "lldap.service"
      "postgresql.service"
    ];
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
