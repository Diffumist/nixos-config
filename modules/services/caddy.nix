{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.caddy;
  caddyCfg = config.services.caddy;
  cloudflareAccessFile = "${pkgs.cloudflare-ip-ranges}/share/caddy/cloudflare-only.caddy";
  cloudflareTrustedProxiesFile = "${pkgs.cloudflare-ip-ranges}/share/caddy/cloudflare-trusted-proxies.caddy";
  cloudflareACMEHosts = lib.filterAttrs (_: host: host.useCloudflareACME) cfg.virtualHosts;
  fail2banHosts = lib.filterAttrs (_: host: host.fail2ban.enable) cfg.virtualHosts;
  caddyPorts = lib.concatMapStringsSep "," toString (
    lib.filter (port: port != null) [
      caddyCfg.httpPort
      caddyCfg.httpsPort
    ]
  );
  fail2banActive = config.services.fail2ban.enable && fail2banHosts != { };
in
{
  options = {
    my.services.caddy = {
      enable = lib.mkEnableOption "the Caddy service";
      cloudflareOnlyHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "app.example.com" ];
        description = ''
          Caddy virtual hosts that only accept HTTP requests whose immediate
          peer is in Cloudflare's published IP ranges.
        '';
      };
      virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                enableCompression = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable response compression for this virtual host.";
                };
                useCloudflareACME = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Provision and use a Cloudflare DNS-01 certificate for this host.";
                };
                oauth2ForwardAuth = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  example = "oauth.example.com";
                  description = "OAuth2 Proxy host used to protect the entire virtual host.";
                };
                fail2ban = {
                  enable = lib.mkEnableOption "Fail2ban jail for this virtual host's Caddy JSON access log";
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = "caddy-${lib.replaceStrings [ "." ":" ] [ "-" "-" ] name}";
                    defaultText = lib.literalExpression ''"caddy-<sanitized-domain>"'';
                    description = "Name of the generated Fail2ban jail and filter.";
                  };
                  methods = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    example = [ "POST" ];
                    description = "HTTP methods to match; empty matches any method.";
                  };
                  uriRegex = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    example = "/api/auth/login";
                    description = ''
                      Regular expression matched against request.uri (anchored at the
                      start, optionally followed by a query string). Null matches any URI.
                    '';
                  };
                  statuses = lib.mkOption {
                    type = lib.types.listOf lib.types.int;
                    default = [
                      401
                      403
                    ];
                    example = [ 401 ];
                    description = "HTTP response status codes that count as a failure.";
                  };
                  maxretry = lib.mkOption {
                    type = lib.types.ints.positive;
                    default = 5;
                    description = "Maximum matching failures within findtime before banning.";
                  };
                  findtime = lib.mkOption {
                    type = lib.types.str;
                    default = "10m";
                    description = "Time window in which maxretry failures trigger a ban.";
                  };
                  bantime = lib.mkOption {
                    type = lib.types.str;
                    default = "24h";
                    description = "Initial ban duration.";
                  };
                };
              };
            }
          )
        );
        default = { };
        description = "Shared policy layered onto Caddy virtual hosts.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions =
      lib.mapAttrsToList (domain: host: {
        assertion = host.fail2ban.statuses != [ ];
        message = ''my.services.caddy.virtualHosts."${domain}".fail2ban.statuses must not be empty.'';
      }) fail2banHosts
      ++ [
        {
          assertion = lib.allUnique (lib.mapAttrsToList (_: host: host.fail2ban.name) fail2banHosts);
          message = "my.services.caddy.virtualHosts.*.fail2ban.name values must be unique.";
        }
      ];

    security.acme = {
      acceptTerms = true;
      defaults.email = "services@diffumist.me";
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy-cloudflare;
      extraConfig = ''
        (oauth2_forward_auth) {
          forward_auth https://{args[0]} {
            uri /oauth2/auth
            copy_headers X-Auth-Request-User X-Auth-Request-Groups X-Auth-Request-Email X-Auth-Request-Preferred-Username
            @error status 401
            handle_response @error {
              redir * https://{args[0]}/oauth2/start?rd={scheme}://{host}{uri}
            }
          }
        }
      '';
      globalConfig = ''
        acme_dns cloudflare {env.CF_API_TOKEN}
        servers {
          import ${cloudflareTrustedProxiesFile}
        }
      '';
      virtualHosts = lib.mkMerge [
        (lib.genAttrs cfg.cloudflareOnlyHosts (_: {
          extraConfig = lib.mkBefore ''
            import ${cloudflareAccessFile}
          '';
        }))
        (lib.mapAttrs (
          domain: host:
          lib.optionalAttrs host.useCloudflareACME {
            useACMEHost = domain;
          }
          // lib.optionalAttrs (host.enableCompression || host.oauth2ForwardAuth != null) {
            extraConfig = lib.mkBefore (
              lib.concatStrings [
                (lib.optionalString host.enableCompression "encode\n")
                (lib.optionalString (
                  host.oauth2ForwardAuth != null
                ) "import oauth2_forward_auth ${host.oauth2ForwardAuth}\n")
              ]
            );
          }
        ) cfg.virtualHosts)
      ];
    };

    security.acme.certs = lib.mapAttrs (_: _: {
      dnsProvider = "cloudflare";
      credentialFiles = {
        CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
        CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      };
    }) cloudflareACMEHosts;

    my.systemd.harden = [ "caddy" ];
    systemd.services.caddy.confinement.enable = true;

    systemd.services.caddy.serviceConfig = {
      # Keep host user namespace so CAP_NET_BIND_SERVICE works on ports 80/443.
      PrivateUsers = false;
      # The whole store, not the config's closure: a closure would change the
      # unit on every Caddyfile edit and turn each reload into a restart.
      BindReadOnlyPaths = [
        "/nix/store"
        "/etc/caddy/caddy_config"
        "-/var/lib/acme"
      ];
      EnvironmentFile = config.sops.templates."caddy-cloudflare.env".path;
      AmbientCapabilities = [
        ""
        "CAP_NET_BIND_SERVICE"
      ];
      CapabilityBoundingSet = [
        ""
        "CAP_NET_BIND_SERVICE"
      ];
    };
    sops.secrets.cloudflare_api_token = {
      sopsFile = ../../profiles/common/secrets/server.yaml;
    };
    sops.templates."caddy-cloudflare.env" = {
      owner = "caddy";
      group = "caddy";
      mode = "0400";
      content = ''
        CF_API_TOKEN=${config.sops.placeholder.cloudflare_api_token}
      '';
    };

    users.users.caddy.extraGroups = [ "acme" ];

    environment.etc = lib.mkIf fail2banActive (
      lib.mapAttrs' (
        _: host:
        let
          f2b = host.fail2ban;
          methodPart = lib.optionalString (
            f2b.methods != [ ]
          ) ''[^{}]*"method":"(?:${lib.concatStringsSep "|" f2b.methods})"'';
          uriPart = lib.optionalString (f2b.uriRegex != null) ''[^{}]*"uri":"${f2b.uriRegex}(?:\?[^"]*)?"'';
          statusPart = lib.concatMapStringsSep "|" toString f2b.statuses;
        in
        lib.nameValuePair "fail2ban/filter.d/${f2b.name}.local" {
          text = ''
            [Definition]
            datepattern = "ts":{EPOCH}
            failregex = ^.*"request":\{[^{}]*"client_ip":"<HOST>"${methodPart}${uriPart}.*"status":(?:${statusPart}),"resp_headers":.*$
            ignoreregex =
          '';
        }
      ) fail2banHosts
    );

    services.fail2ban.jails = lib.mkIf fail2banActive (
      lib.mapAttrs' (
        domain: host:
        let
          f2b = host.fail2ban;
        in
        lib.nameValuePair f2b.name {
          settings = {
            enabled = true;
            filter = f2b.name;
            backend = "auto";
            logpath = "${caddyCfg.logDir}/access-${domain}.log";
            maxretry = f2b.maxretry;
            findtime = f2b.findtime;
            bantime = f2b.bantime;
          }
          // lib.optionalAttrs (caddyPorts != "") {
            port = caddyPorts;
            protocol = "tcp,udp";
          };
        }
      ) fail2banHosts
    );

    systemd.tmpfiles.rules = lib.mkIf fail2banActive (
      [
        "d ${caddyCfg.logDir} 0755 ${caddyCfg.user} ${caddyCfg.group} -"
      ]
      ++ lib.mapAttrsToList (
        domain: _: "f ${caddyCfg.logDir}/access-${domain}.log 0640 ${caddyCfg.user} ${caddyCfg.group} -"
      ) fail2banHosts
    );

    systemd.services.fail2ban = lib.mkIf fail2banActive {
      after = [ "caddy.service" ];
    };

    networking.firewall = {
      allowedTCPPorts = lib.filter (port: port != null) [
        caddyCfg.httpPort
        caddyCfg.httpsPort
      ];
      allowedUDPPorts = lib.optional (caddyCfg.httpsPort != null) caddyCfg.httpsPort;
    };

    my.networking = {
      usedTCPPorts = {
        "caddy-admin" = 2019;
      }
      // lib.optionalAttrs (caddyCfg.httpPort != null) { "caddy-http" = caddyCfg.httpPort; }
      // lib.optionalAttrs (caddyCfg.httpsPort != null) { "caddy-https" = caddyCfg.httpsPort; };
      usedUDPPorts = lib.optionalAttrs (caddyCfg.httpsPort != null) {
        "caddy-http3" = caddyCfg.httpsPort;
      };
    };
  };
}
