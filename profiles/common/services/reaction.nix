{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.reaction;
  reactionCfg = config.services.reaction;
  caddyCfg = config.services.caddy;

  nft = "${pkgs.nftables}/bin/nft";
  journalctl = "${config.systemd.package}/bin/journalctl";
  tail = "${pkgs.coreutils}/bin/tail";

  hasSsh = config.services.openssh.enable && config.services.openssh.ports != [ ];
  hasWeb = cfg.webRules != { };

  sshPorts = config.services.openssh.ports;
  webTcpPorts =
    let
      ports = lib.filter (port: port != null) [
        caddyCfg.httpPort
        caddyCfg.httpsPort
      ];
    in
    if ports != [ ] then
      ports
    else
      [
        80
        443
      ];
  webUdpPorts =
    let
      ports = lib.optional (caddyCfg.httpsPort != null) caddyCfg.httpsPort;
    in
    if ports != [ ] then ports else [ 443 ];

  fmtPortSet = ports: "{ ${lib.concatMapStringsSep ", " toString ports} }";

  nftInitFile = pkgs.writeText "reaction.nft" (
    ''
      destroy table inet reaction
      table inet reaction {
    ''
    + lib.optionalString hasSsh ''
      set ssh_v4 {
        type ipv4_addr
      }
      set ssh_v6 {
        type ipv6_addr
        flags interval
      }
      set ssh_recidive_v4 {
        type ipv4_addr
      }
      set ssh_recidive_v6 {
        type ipv6_addr
        flags interval
      }
    ''
    + lib.optionalString hasWeb ''
      set web_v4 {
        type ipv4_addr
      }
      set web_v6 {
        type ipv6_addr
        flags interval
      }
      set web_recidive_v4 {
        type ipv4_addr
      }
      set web_recidive_v6 {
        type ipv6_addr
        flags interval
      }
    ''
    + ''
      chain input {
        type filter hook input priority filter - 10; policy accept;
    ''
    + lib.optionalString hasSsh ''
      tcp dport ${fmtPortSet sshPorts} ct state established,related accept
      tcp dport ${fmtPortSet sshPorts} ip saddr @ssh_v4 drop
      tcp dport ${fmtPortSet sshPorts} ip6 saddr @ssh_v6 drop
      tcp dport ${fmtPortSet sshPorts} ip saddr @ssh_recidive_v4 drop
      tcp dport ${fmtPortSet sshPorts} ip6 saddr @ssh_recidive_v6 drop
    ''
    + lib.optionalString hasWeb ''
      tcp dport ${fmtPortSet webTcpPorts} ip saddr @web_v4 drop
      tcp dport ${fmtPortSet webTcpPorts} ip6 saddr @web_v6 drop
      tcp dport ${fmtPortSet webTcpPorts} ip saddr @web_recidive_v4 drop
      tcp dport ${fmtPortSet webTcpPorts} ip6 saddr @web_recidive_v6 drop
      udp dport ${fmtPortSet webUdpPorts} ip saddr @web_v4 drop
      udp dport ${fmtPortSet webUdpPorts} ip6 saddr @web_v6 drop
      udp dport ${fmtPortSet webUdpPorts} ip saddr @web_recidive_v4 drop
      udp dport ${fmtPortSet webUdpPorts} ip6 saddr @web_recidive_v6 drop
    ''
    + ''
        }
      }
    ''
  );

  mkNftBanActions =
    {
      setPrefix,
      bantime,
      recidiveTag ? null,
    }:
    {
      ban4 = {
        cmd = [
          nft
          "add"
          "element"
          "inet"
          "reaction"
          "${setPrefix}_v4"
          "{ <ip> }"
        ];
        ipv4only = true;
      };
      ban6 = {
        cmd = [
          nft
          "add"
          "element"
          "inet"
          "reaction"
          "${setPrefix}_v6"
          "{ <ip> }"
        ];
        ipv6only = true;
      };
      unban4 = {
        cmd = [
          nft
          "destroy"
          "element"
          "inet"
          "reaction"
          "${setPrefix}_v4"
          "{ <ip> }"
        ];
        after = bantime;
        ipv4only = true;
      };
      unban6 = {
        cmd = [
          nft
          "destroy"
          "element"
          "inet"
          "reaction"
          "${setPrefix}_v6"
          "{ <ip> }"
        ];
        after = bantime;
        ipv6only = true;
      };
    }
    // lib.optionalAttrs (recidiveTag != null) {
      recidive = {
        type = "virtual";
        # Prevent reaction restart replays from double-counting the same ban.
        oneshot = true;
        options = {
          to = "recidive";
          send = "${recidiveTag} <ip>";
        };
      };
    };

  webStreams = lib.mapAttrs (_: rule: {
    cmd =
      if rule.unit != null then
        [
          journalctl
          "-fn0"
          "-o"
          "cat"
          "-u"
          rule.unit
        ]
      else
        [
          tail
          "-F"
          "-n0"
          rule.logFile
        ];
    filters.ban = {
      inherit (rule) regex retry retryperiod;
      actions = mkNftBanActions {
        setPrefix = "web";
        inherit (rule) bantime;
        recidiveTag = "web";
      };
    };
  }) cfg.webRules;

  recidiveFilters =
    lib.optionalAttrs hasSsh {
      ssh = {
        regex = [ "^ssh <ip>(?:/64)?$" ];
        retry = 3;
        retryperiod = "7d";
        actions = mkNftBanActions {
          setPrefix = "ssh_recidive";
          bantime = "7d";
        };
      };
    }
    // lib.optionalAttrs hasWeb {
      web = {
        regex = [ "^web <ip>(?:/64)?$" ];
        retry = 3;
        retryperiod = "7d";
        actions = mkNftBanActions {
          setPrefix = "web_recidive";
          bantime = "7d";
        };
      };
    };
in
{
  options.my.services.reaction = {
    webRules = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            unit = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Systemd unit to monitor with journalctl.";
            };
            logFile = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Log file path to monitor with tail -F -n0.";
            };
            regex = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Reaction regexes containing <ip> to match failures.";
            };
            retry = lib.mkOption {
              type = lib.types.ints.positive;
              default = 5;
              description = "Matching failures within retryperiod before banning.";
            };
            retryperiod = lib.mkOption {
              type = lib.types.str;
              default = "10m";
              description = "Sliding window for counting retries.";
            };
            bantime = lib.mkOption {
              type = lib.types.str;
              default = "1h";
              description = "Initial ban duration before recidive escalation.";
            };
          };
        }
      );
      default = { };
      description = "Web-scoped (HTTP/HTTPS ports) reaction ban rules.";
    };
  };

  config = {
    assertions =
      lib.mapAttrsToList (name: rule: {
        assertion = (rule.unit != null) != (rule.logFile != null);
        message = ''my.services.reaction.webRules."${name}" must set exactly one of unit or logFile.'';
      }) cfg.webRules
      ++ lib.mapAttrsToList (name: rule: {
        assertion = rule.regex != [ ];
        message = ''my.services.reaction.webRules."${name}".regex must not be empty.'';
      }) cfg.webRules;

    services.reaction = {
      enable = lib.mkDefault true;
      runAsRoot = false;
      settings = {
        plugins = {
          ipset.enable = false;
          virtual.enable = true;
        };

        patterns.ip = {
          type = "ip";
          ipv6mask = 64;
          ignore = [
            "127.0.0.1"
            "::1"
          ];
          ignorecidr = [
            "127.0.0.0/8"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "fc00::/7"
            "fe80::/10"
          ];
        };

        start = [
          [
            nft
            "-f"
            "${nftInitFile}"
          ]
        ];
        stop = [
          [
            nft
            "destroy"
            "table"
            "inet"
            "reaction"
          ]
        ];

        streams =
          lib.optionalAttrs hasSsh {
            sshd = {
              cmd = [
                journalctl
                "-fn0"
                "-o"
                "cat"
                "-u"
                "sshd.service"
              ];
              filters.failedlogin = {
                regex = [
                  "Invalid user .* from <ip> port"
                  "Failed (?:password|publickey) for .* from <ip> port"
                  "authentication failure;.*rhost=<ip>(?: |$)"
                  "Maximum authentication attempts exceeded for .* from <ip> port"
                  "banner exchange: Connection from <ip> port [0-9]+: invalid format"
                  "Did not receive identification string from <ip> port"
                ];
                retry = 20;
                retryperiod = "10m";
                actions = mkNftBanActions {
                  setPrefix = "ssh";
                  bantime = "1h";
                  recidiveTag = "ssh";
                };
              };
            };
          }
          // webStreams
          // lib.optionalAttrs (recidiveFilters != { }) {
            recidive = {
              type = "virtual";
              filters = recidiveFilters;
            };
          };
      };
    };

    users.users.reaction = lib.mkIf (reactionCfg.enable && !reactionCfg.runAsRoot) {
      extraGroups = [ "systemd-journal" ];
    };

    my.systemd.harden = lib.mkIf reactionCfg.enable [ "reaction" ];
    systemd.services.reaction = lib.mkIf reactionCfg.enable {
      after = [ "nftables.service" ];
      path = lib.mkForce [ ];
      unitConfig.ConditionCapability = "CAP_NET_ADMIN";
      serviceConfig = {
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        # journalctl -f reads /proc/sys/kernel/random/boot_id.
        ProcSubset = "all";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
      };
    };
  };
}
