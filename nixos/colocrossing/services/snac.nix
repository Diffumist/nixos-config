{
  lib,
  pkgs,
  config,
  ...
}:
{
  # snac adduser /var/lib/snac <uid>
  users.groups.snac = { };
  users.users.snac = {
    isSystemUser = true;
    group = "snac";
    home = "/var/lib/snac";
  };

  systemd.services.snac-init = {
    description = "Initialize and configure snac data directory";
    before = [ "snac.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      if [ ! -e /var/lib/snac/server.json ]; then
        if [ -d /var/lib/snac ]; then
          rmdir /var/lib/snac
        fi

        printf '127.0.0.1\n8001\ndiffumist.me\n/fedi\n\n' \
          | ${lib.getExe pkgs.snac2} init /var/lib/snac
      fi

      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      ${lib.getExe pkgs.jq} \
        '.address = "127.0.0.1" | .port = 8001 | .host = "diffumist.me" | .prefix = "/fedi"' \
        /var/lib/snac/server.json > "$tmp"
      ${pkgs.coreutils}/bin/install -o snac -g snac -m 0640 "$tmp" /var/lib/snac/server.json
      ${pkgs.coreutils}/bin/rm -f "$tmp"

      chown -R snac:snac /var/lib/snac
      chmod 0750 /var/lib/snac
    '';
  };

  systemd.services.snac = {
    description = "snac ActivityPub service";
    after = [
      "network-online.target"
      "snac-init.service"
    ];
    wants = [
      "network-online.target"
      "snac-init.service"
    ];
    requires = [ "snac-init.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "snac";
      Group = "snac";
      WorkingDirectory = "/var/lib/snac";
      ExecStart = "${lib.getExe pkgs.snac2} httpd /var/lib/snac";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/snac" ];
    };
  };
  my.services.caddy.enable = true;
  services.caddy.virtualHosts."diffumist.me" = {
    useACMEHost = "diffumist.me";
    extraConfig = ''
      encode zstd gzip
      request_body {
        max_size 128MB
      }

      @snac {
        path /fedi
        path /fedi/*
        path /.well-known/webfinger
        path /.well-known/nodeinfo
        path /.well-known/host-meta
        path /api/v1/
        path /api/v1/*
        path /api/v2/
        path /api/v2/*
        path /authorize_interaction
        path /oauth
        path /oauth/*
        path /share
      }

      handle @snac {
        reverse_proxy 127.0.0.1:8001
      }

      handle {
        reverse_proxy https://diffumist-github-io.pages.dev {
          header_up Host diffumist-github-io.pages.dev
        }
      }
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs."diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
