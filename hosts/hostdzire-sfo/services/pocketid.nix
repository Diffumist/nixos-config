{ config, ... }:
let
  domain = "id.418.cat";
  database = config.services.pocket-id.user;
  port = 1411;
in
{
  sops.secrets = {
    "pocketid/encryption_key" = {
      sopsFile = ./pocketid.yaml;
      owner = config.services.pocket-id.user;
      group = config.services.pocket-id.group;
      restartUnits = [ "pocket-id.service" ];
    };
    "pocketid/static_api_key" = {
      sopsFile = ./pocketid.yaml;
      owner = config.services.pocket-id.user;
      group = config.services.pocket-id.group;
      restartUnits = [ "pocket-id.service" ];
    };
  };

  services.pocket-id = {
    enable = true;
    credentials = {
      ENCRYPTION_KEY = config.sops.secrets."pocketid/encryption_key".path;
      STATIC_API_KEY = config.sops.secrets."pocketid/static_api_key".path;
    };
    settings = {
      APP_URL = "https://${domain}";
      APP_NAME = "DiftNet";
      DB_CONNECTION_STRING = "postgresql:///${database}?host=/run/postgresql";
      HOST = "127.0.0.1";
      PORT = port;
      TRUST_PROXY = true;
      UI_CONFIG_DISABLED = true;
      ALLOW_INSECURE_CALLBACK_URLS = false;
    };
  };

  my.services.postgresql.enable = true;
  services.postgresql = {
    ensureDatabases = [ database ];
    ensureUsers = [
      {
        name = database;
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.pocket-id = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain}.useCloudflareACME = true;
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
