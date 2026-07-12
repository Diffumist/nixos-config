{ config, lib, ... }:
let
  domains = {
    me = "diffumist.me";
    io = "diffumist.io";
    moe = "diffumist.moe";
    xyz = "503418.xyz";
  };
  domainList = builtins.attrValues domains;
  authDomains = map (domain: "auth.${domain}") domainList;
  acmeCert = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
in
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
        cookies = map (domain: {
          inherit domain;
          authelia_url = "https://auth.${domain}";
        }) domainList;
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
            domain = authDomains;
            policy = "bypass";
          }
          {
            domain = [
              "music.${domains.me}"
              "tavern.${domains.me}"
              "token.${domains.me}"
            ];
            policy = "two_factor";
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

  my.services.caddy.enable = true;
  services.caddy.virtualHosts = lib.genAttrs authDomains (domain: {
    useACMEHost = domain;
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:9091
    '';
  });
  security.acme.certs = lib.genAttrs authDomains (_: acmeCert);
}
