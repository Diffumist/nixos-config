{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.sing-box;
  acme = {
    data_directory = "acme";
    default_server_name = cfg.domain;
    disable_http_challenge = true;
    disable_tls_alpn_challenge = true;
    dns01_challenge = {
      provider = "cloudflare";
      api_token._secret = "/run/secrets/cloudflare_api_token";
    };
    domain = [ cfg.domain ];
    email = "services@diffumist.me";
    provider = "letsencrypt";
  };
  users = [
    {
      name = "default";
      password._secret = "/run/secrets/singbox_passwd";
    }
  ];
in
{
  options.my.services.sing-box = {
    enable = lib.mkEnableOption "the shared sing-box proxy service";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain used for ACME certificate issuance.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = "Shared TCP and UDP listen port.";
    };
  };

  config = lib.mkIf cfg.enable {

    sops.secrets.singbox_passwd = {
      sopsFile = ../../profiles/common/secrets/server.yaml;
      owner = "sing-box";
      group = "sing-box";
      restartUnits = [ "sing-box.service" ];
    };

    services.sing-box = {
      enable = true;
      settings = {
        experimental.cache_file = {
          enabled = true;
          path = "cache.db";
        };

        dns = {
          servers = [
            {
              type = "tls";
              tag = "cloudflare-dns";
              server = "1.1.1.1";
              server_port = 853;
              tls = {
                enabled = true;
                server_name = "cloudflare-dns.com";
              };
            }
          ];
          final = "cloudflare-dns";
          strategy = "prefer_ipv4";
        };

        inbounds = [
          {
            listen = "::";
            listen_port = cfg.port;
            tag = "anytls-tcp-in";
            tls = {
              inherit acme;
              alpn = [
                "h2"
                "http/1.1"
              ];
              enabled = true;
            };
            type = "anytls";
            inherit users;
          }
          {
            listen = "::";
            listen_port = cfg.port;
            masquerade = {
              rewrite_host = true;
              type = "proxy";
              url = "https://macguy.io";
            };
            tag = "hysteria-udp-in";
            tls = {
              inherit acme;
              alpn = [ "h3" ];
              enabled = true;
            };
            type = "hysteria2";
            inherit users;
          }
        ];

        log = {
          level = "info";
          timestamp = true;
        };

        outbounds = [
          {
            tag = "direct";
            type = "direct";
          }
        ];

        route = {
          auto_detect_interface = true;
          default_domain_resolver = {
            server = "cloudflare-dns";
            strategy = "prefer_ipv4";
          };
          final = "direct";
          rules = [
            {
              action = "sniff";
              inbound = [
                "anytls-tcp-in"
                "hysteria-udp-in"
              ];
              sniffer = [
                "http"
                "tls"
                "quic"
                "bittorrent"
              ];
              timeout = "500ms";
            }
            {
              action = "reject";
              protocol = [ "bittorrent" ];
            }
          ];
        };
      };
    };

    systemd.services.sing-box.serviceConfig.ExecStartPre = lib.mkAfter [
      "${lib.getExe config.services.sing-box.package} -D \${STATE_DIRECTORY} -c \${RUNTIME_DIRECTORY}/config.json check"
    ];

    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
