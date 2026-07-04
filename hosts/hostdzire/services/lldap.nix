{
  config,
  lib,
  pkgs,
  ...
}:

{
  sops.secrets = {
    "lldap/admin_password" = {
      group = "lldap-secrets";
      mode = "0440";
    };
    "lldap/jwt_secret" = {
      group = "lldap-secrets";
      mode = "0440";
    };
    "lldap/key_seed" = {
      group = "lldap-secrets";
      mode = "0440";
    };
  };
  services.lldap = {
    enable = true;
    database = {
      type = "postgresql";
      createLocally = true;
    };

    settings = {
      ldap_host = "127.0.0.1";
      ldap_port = 3890;
      http_host = "127.0.0.1";
      http_port = 17170;
      http_url = "https://ldap.diffumist.me";
      ldap_base_dn = "dc=diffumist,dc=me";
      ldap_user_dn = "diffumist";
      ldap_user_email = "me@diffumist.me";
      ldap_user_pass_file = config.sops.secrets."lldap/admin_password".path;
      jwt_secret_file = config.sops.secrets."lldap/jwt_secret".path;
      force_ldap_user_pass_reset = "always";
    };

    environment = {
      LLDAP_KEY_SEED_FILE = config.sops.secrets."lldap/key_seed".path;
    };
  };

  users.groups.lldap-secrets = { };
  systemd.services.lldap.serviceConfig.SupplementaryGroups = [ "lldap-secrets" ];

  services.caddy.virtualHosts."ldap.diffumist.me".extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:${toString config.services.lldap.settings.http_port}
  '';
}
