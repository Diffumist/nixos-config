{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.caddy;
  caddyCfg = config.services.caddy;
  cloudflareIpsData = builtins.fromJSON (builtins.readFile ../../pkgs/cloudflare-ip-ranges/ips.json);
  cloudflareRanges = cloudflareIpsData.result.ipv4_cidrs ++ cloudflareIpsData.result.ipv6_cidrs;
  ranetRanges = lib.concatMap (node: [
    node.ipv4
    node.ipv6
  ]) (lib.attrValues (config.my.services.ranet.nodes or { }));
  cloudflareAccessFile = pkgs.writeText "cloudflare-only.caddy" ''
    @not_cloudflare_proxy not remote_ip ${
      lib.concatStringsSep " " (
        cloudflareRanges
        ++ ranetRanges
        ++ [
          "127.0.0.1"
          "::1"
        ]
      )
    }
    abort @not_cloudflare_proxy
  '';
  cloudflareTrustedProxiesFile = "${pkgs.cloudflare-ip-ranges}/share/caddy/cloudflare-trusted-proxies.caddy";
  cloudflareACMEHosts = lib.filterAttrs (_: host: host.useCloudflareACME) cfg.virtualHosts;
  wildcardACMEZones = lib.unique (
    lib.filter (zone: zone != null) (
      lib.mapAttrsToList (_: host: host.acmeWildcardZone) cfg.virtualHosts
    )
  );
  originCertHosts = lib.filterAttrs (_: host: host.useCloudflareOriginCert) cfg.virtualHosts;
  hasOriginCertHosts = originCertHosts != { };
  cloudflareOnlyHosts = lib.unique (
    cfg.cloudflareOnlyHosts
    ++ lib.attrNames (lib.filterAttrs (_: host: host.cloudflareOnly) cfg.virtualHosts)
  );
  reactionHosts = lib.filterAttrs (_: host: host.reaction.enable) cfg.virtualHosts;
  reactionActive = config.services.reaction.enable && reactionHosts != { };
  originCertPath = config.sops.secrets.cloudflare_origin_cert.path;
  originKeyPath = config.sops.secrets.cloudflare_origin_key.path;
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
                useCloudflareOriginCert = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Use the shared Cloudflare Origin CA certificate from SOPS for this proxied host.";
                };
                acmeWildcardZone = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  example = "example.com";
                  description = "Provision and use a shared Cloudflare DNS-01 wildcard certificate (*.<zone>) for this host.";
                };
                cloudflareOnly = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Restrict HTTP access to Cloudflare's published IP ranges (plus ranet management peers).";
                };
                oauth2ForwardAuth = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  example = "oauth.example.com";
                  description = "OAuth2 Proxy host used to protect the entire virtual host.";
                };
                reaction = {
                  enable = lib.mkEnableOption "Reaction ban rule for this virtual host's Caddy JSON access log";
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = "caddy-${lib.replaceStrings [ "." ":" ] [ "-" "-" ] name}";
                    defaultText = lib.literalExpression ''"caddy-<sanitized-domain>"'';
                    description = "Name of the generated Reaction stream.";
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
                  retry = lib.mkOption {
                    type = lib.types.ints.positive;
                    default = 5;
                    description = "Maximum matching failures within retryperiod before banning.";
                  };
                  retryperiod = lib.mkOption {
                    type = lib.types.str;
                    default = "10m";
                    description = "Time window in which retry failures trigger a ban.";
                  };
                  bantime = lib.mkOption {
                    type = lib.types.str;
                    default = "1h";
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
        assertion = host.reaction.statuses != [ ];
        message = ''my.services.caddy.virtualHosts."${domain}".reaction.statuses must not be empty.'';
      }) reactionHosts
      ++ lib.mapAttrsToList (
        domain: host:
        let
          tlsModes = lib.count lib.id [
            host.useCloudflareACME
            host.useCloudflareOriginCert
            (host.acmeWildcardZone != null)
          ];
        in
        {
          assertion = tlsModes <= 1;
          message = ''my.services.caddy.virtualHosts."${domain}" may set at most one of useCloudflareACME, useCloudflareOriginCert, or acmeWildcardZone.'';
        }
      ) cfg.virtualHosts
      ++ lib.mapAttrsToList (
        domain: host:
        let
          suffix = ".${host.acmeWildcardZone}";
          prefix = lib.removeSuffix suffix domain;
        in
        {
          assertion = lib.hasSuffix suffix domain && prefix != "" && !(lib.hasInfix "." prefix);
          message = ''my.services.caddy.virtualHosts."${domain}".acmeWildcardZone ("${host.acmeWildcardZone}") only covers single-label subdomains of ${host.acmeWildcardZone}.'';
        }
      ) (lib.filterAttrs (_: host: host.acmeWildcardZone != null) cfg.virtualHosts)
      ++ [
        {
          assertion = lib.allUnique (lib.mapAttrsToList (_: host: host.reaction.name) reactionHosts);
          message = "my.services.caddy.virtualHosts.*.reaction.name values must be unique.";
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
        order abort first
        acme_dns cloudflare {env.CF_API_TOKEN}
        servers {
          import ${cloudflareTrustedProxiesFile}
        }
      '';
      virtualHosts = lib.mkMerge [
        (lib.genAttrs cloudflareOnlyHosts (_: {
          extraConfig = lib.mkBefore ''
            import ${cloudflareAccessFile}
          '';
        }))
        (lib.mapAttrs (
          domain: host:
          lib.optionalAttrs host.useCloudflareACME {
            useACMEHost = domain;
          }
          // lib.optionalAttrs (host.acmeWildcardZone != null) {
            useACMEHost = "wildcard.${host.acmeWildcardZone}";
          }
          // lib.optionalAttrs (config.services.reaction.enable && host.reaction.enable) {
            # Keep rotated access logs group-readable for the non-root reaction user.
            logFormat = lib.mkDefault ''
              output file ${caddyCfg.logDir}/access-${domain}.log {
                mode 640
              }
            '';
          }
          //
            lib.optionalAttrs
              (host.useCloudflareOriginCert || host.enableCompression || host.oauth2ForwardAuth != null)
              {
                extraConfig = lib.mkBefore (
                  lib.concatStrings [
                    (lib.optionalString host.useCloudflareOriginCert "tls ${originCertPath} ${originKeyPath}\n")
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

    security.acme.certs = lib.mkMerge [
      (lib.mapAttrs (_: _: {
        dnsProvider = "cloudflare";
        credentialFiles = {
          CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
          CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
        };
      }) cloudflareACMEHosts)
      (lib.listToAttrs (
        map (zone: {
          name = "wildcard.${zone}";
          value = {
            domain = "*.${zone}";
            dnsProvider = "cloudflare";
            credentialFiles = {
              CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
              CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
            };
          };
        }) wildcardACMEZones
      ))
    ];

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
      ]
      ++ lib.optionals hasOriginCertHosts [
        originCertPath
        originKeyPath
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
    sops.secrets = {
      cloudflare_api_token = {
        sopsFile = ../../profiles/common/secrets/server.yaml;
      };
    }
    // lib.optionalAttrs hasOriginCertHosts {
      cloudflare_origin_cert = {
        sopsFile = ../../profiles/common/secrets/server.yaml;
        owner = caddyCfg.user;
        group = caddyCfg.group;
        mode = "0400";
        restartUnits = [ "caddy.service" ];
      };
      cloudflare_origin_key = {
        sopsFile = ../../profiles/common/secrets/server.yaml;
        owner = caddyCfg.user;
        group = caddyCfg.group;
        mode = "0400";
        restartUnits = [ "caddy.service" ];
      };
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

    my.services.reaction.webRules = lib.mkIf reactionActive (
      lib.mapAttrs' (
        domain: host:
        let
          rule = host.reaction;
          methodPart = lib.optionalString (
            rule.methods != [ ]
          ) ''[^{}]*"method":"(?:${lib.concatStringsSep "|" rule.methods})"'';
          uriPart = lib.optionalString (rule.uriRegex != null) ''[^{}]*"uri":"${rule.uriRegex}(?:\?[^"]*)?"'';
          statusPart = lib.concatMapStringsSep "|" toString rule.statuses;
        in
        lib.nameValuePair rule.name {
          logFile = "${caddyCfg.logDir}/access-${domain}.log";
          regex = [
            ''"request":\{[^{}]*"client_ip":"<ip>"${methodPart}${uriPart}.*"status":(?:${statusPart}),"resp_headers":''
          ];
          inherit (rule) retry retryperiod bantime;
        }
      ) reactionHosts
    );

    systemd.tmpfiles.rules = lib.mkIf reactionActive (
      [
        "d ${caddyCfg.logDir} 0755 ${caddyCfg.user} ${caddyCfg.group} -"
      ]
      ++ lib.mapAttrsToList (
        domain: _: "f ${caddyCfg.logDir}/access-${domain}.log 0640 ${caddyCfg.user} ${caddyCfg.group} -"
      ) reactionHosts
    );

    users.users.reaction = lib.mkIf (reactionActive && !config.services.reaction.runAsRoot) {
      extraGroups = [ caddyCfg.group ];
    };

    systemd.services.reaction = lib.mkIf reactionActive {
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
