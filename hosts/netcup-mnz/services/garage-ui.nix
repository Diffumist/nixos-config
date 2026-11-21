{
  config,
  helpers,
  lib,
  pkgs,
  ...
}:

let
  domain = "s3-ui.418.cat";
  port = 3904;
  user = "garage-ui";
  yaml = pkgs.formats.yaml { };
  settings = yaml.generate "garage-ui.yaml" {
    server = {
      host = "127.0.0.1";
      inherit port;
      environment = "production";
      domain = domain;
      protocol = "https";
      root_url = "https://${domain}";
    };
    garage = {
      endpoint = "http://127.0.0.1:3900";
      region = "garage";
      admin_endpoint = "http://127.0.0.1:3903";
    };
    auth = {
      metrics_public = false;
      admin.enabled = false;
      token.enabled = false;
      oidc = {
        enabled = true;
        provider_name = "Pocket ID";
        client_id = "garage-ui";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        issuer_url = "https://id.418.cat";
        role_attribute_path = "groups";
        admin_role = "diffumist";
        session_max_age = 86400;
        cookie_name = "garage_ui_session";
        cookie_secure = true;
        cookie_http_only = true;
        cookie_same_site = "lax";
      };
    };
    cors.enabled = false;
    logging = {
      level = "info";
      format = "json";
    };
  };
in
{
  sops.secrets =
    lib.genAttrs
      [
        "garage-ui/admin_token"
        "garage-ui/oidc_client_secret"
        "garage-ui/jwt_private_key"
      ]
      (_: {
        owner = user;
        group = user;
        mode = "0400";
        restartUnits = [ "garage-ui.service" ];
      });

  users = {
    groups.${user} = { };
    users.${user} = {
      isSystemUser = true;
      group = user;
    };
  };

  systemd.services.garage-ui = helpers.systemd.mkService {
    description = "Garage web administration interface";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    requires = [ "garage.service" ];
    after = [
      "garage.service"
      "network-online.target"
    ];
    environment = {
      GARAGE_UI_GARAGE_ADMIN_TOKEN_FILE = config.sops.secrets."garage-ui/admin_token".path;
      GARAGE_UI_AUTH_OIDC_CLIENT_SECRET_FILE = config.sops.secrets."garage-ui/oidc_client_secret".path;
      GARAGE_UI_AUTH_JWT_PRIVATE_KEY_FILE = config.sops.secrets."garage-ui/jwt_private_key".path;
    };
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.garage-ui} -config ${settings}";
      Restart = "on-failure";
      RestartSec = "5s";
      User = user;
      Group = user;
      UMask = "0077";
    };
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain}.useCloudflareACME = true;
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy 127.0.0.1:${toString port}
  '';

  my.networking.usedTCPPorts.garage-ui = port;
}
