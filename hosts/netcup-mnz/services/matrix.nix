{ config, ... }:
let
  domain = "mux.im";
  port = 6167;
in
{
  sops.secrets.tuwunel_registration_token.owner = config.services.matrix-tuwunel.user;
  sops.secrets.tuwunel_oidc_secret.owner = config.services.matrix-tuwunel.user;

  services.matrix-tuwunel = {
    enable = true;
    settings.global = {
      server_name = domain;
      port = [ port ];
      # Registration is gated by the token; the first account becomes admin.
      allow_registration = false;
      registration_token_file = config.sops.secrets.tuwunel_registration_token.path;
      identity_provider = [
        {
          brand = "PocketID";
          client_id = "0f44bde0-a99b-4e16-b1a9-876f8c55196c";
          client_secret_file = config.sops.secrets.tuwunel_oidc_secret.path;
          unique_id_fallbacks = false;
          trusted = true;
          issuer_url = "https://id.418.cat";
          callback_url = "https://mux.im/_matrix/client/unstable/login/sso/callback/0f44bde0-a99b-4e16-b1a9-876f8c55196c";
        }
      ];
    };
  };

  my.systemd.harden = [ "tuwunel" ];
  systemd.services.tuwunel = {
    confinement = {
      enable = true;
      # TUWUNEL_CONFIG is passed via Environment rather than ExecStart.
      fullUnit = true;
    };
    serviceConfig.BindReadOnlyPaths = [
      config.sops.secrets.tuwunel_registration_token.path
      config.sops.secrets.tuwunel_oidc_secret.path
    ];
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain} = {
      useCloudflareACME = true;
      reaction = {
        enable = true;
        name = "matrix-caddy";
        methods = [ "POST" ];
        uriRegex = "/_matrix/client/[^\"?]+/login";
        statuses = [
          401
          403
        ];
        retry = 5;
      };
    };
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    # Delegation lets federation and clients use 443 instead of 8448.
    handle /.well-known/matrix/server {
      header Content-Type application/json
      respond `{"m.server":"${domain}:443"}`
    }

    handle /.well-known/matrix/client {
      header Content-Type application/json
      header Access-Control-Allow-Origin "*"
      respond `{"m.homeserver":{"base_url":"https://${domain}"}}`
    }

    handle /_matrix/* {
      reverse_proxy 127.0.0.1:${toString port}
    }

    handle {
      respond 404
    }
  '';

  my.networking.usedTCPPorts.tuwunel = port;
}
