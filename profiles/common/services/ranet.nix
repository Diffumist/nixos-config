{
  config,
  hostName,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.ranet;
  port = 13000;
  # ESP-in-UDP over a 1500-byte underlay; lower it if a provider path is tighter.
  mtu = 1400;
  dummy = "ranet";
  linkPrefix = "ranet-";

  active = lib.filterAttrs (_: node: node.publicKey != null) cfg.nodes;
  enabled = active ? ${hostName};
  local = active.${hostName};
  peers = removeAttrs active [ hostName ];

  # ponytail: one IPv4 endpoint per node. Add an ip6 endpoint (and a route
  # metric per family in updown) when a v6-only node joins.
  endpoint = address: {
    serial_number = "0";
    address_family = "ip4";
    inherit address port;
  };

  json = pkgs.formats.json { };
  registry = json.generate "ranet-registry.json" (
    lib.mapAttrsToList (name: node: {
      organization = name;
      public_key = "-----BEGIN PUBLIC KEY-----\n${node.publicKey}\n-----END PUBLIC KEY-----\n";
      nodes = [
        {
          common_name = name;
          endpoints = [ (endpoint node.endpoint) ];
        }
      ];
    }) active
  );
  ranetConfig = json.generate "ranet-config.json" {
    organization = hostName;
    common_name = hostName;
    endpoints = [
      (
        endpoint null
        // {
          updown = lib.getExe updown;
          fwmark = null;
        }
      )
    ];
  };

  # The mesh is full, so every peer is adjacent and one host route per family
  # on its XFRM interface is the whole routing layer.
  updown = pkgs.writeShellApplication {
    name = "ranet-updown";
    runtimeInputs = [
      pkgs.gnused
      pkgs.iproute2
    ];
    text = ''
      case "$PLUTO_VERB" in
        up-*) ;;
        *) exit 0 ;;
      esac

      peer=$(sed -n 's/.*CN=\([^,]*\).*/\1/p' <<<"$PLUTO_PEER_ID")
      case "$peer" in
      ${lib.concatStrings (
        lib.mapAttrsToList (name: node: ''
          ${name}) v4=${node.ipv4} v6=${node.ipv6} ;;
        '') peers
      )}
        *) exit 0 ;;
      esac

      # Links are never deleted on down: a replaced SA can report down after
      # its successor reported up, and deleting then would blackhole a live
      # tunnel. A link without an SA drops traffic, which is all a full mesh
      # can do for an unreachable peer anyway.
      link=${linkPrefix}$(printf '%08x' "$PLUTO_IF_ID_OUT")
      ip link add "$link" type xfrm if_id "$PLUTO_IF_ID_OUT" 2>/dev/null || true
      ip link set "$link" mtu ${toString mtu} up
      ip route replace "$v4/32" dev "$link" src ${local.ipv4}
      ip -6 route replace "$v6/128" dev "$link" src ${local.ipv6}
    '';
  };

  ranet = lib.escapeShellArgs [
    (lib.getExe pkgs.ranet)
    "--config=${ranetConfig}"
    "--registry=${registry}"
    "--key=${
      if cfg.privateKeyFile != null then
        cfg.privateKeyFile
      else
        config.sops.secrets.ranet_private_key.path
    }"
  ];
in
{
  options.my.services.ranet = {
    nodes = lib.mkOption {
      description = ''
        Management mesh members keyed by host name. A node without a public
        key only reserves its addresses; setting the key enrolls the host.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            endpoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Public IPv4 host name or address; null for a node that only dials out.";
            };
            ipv4 = lib.mkOption {
              type = lib.types.str;
              description = "Management IPv4 address.";
            };
            ipv6 = lib.mkOption {
              type = lib.types.str;
              description = "Management IPv6 address.";
            };
            publicKey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Base64 body of the node's Ed25519 public key PEM.";
            };
          };
        }
      );
      default =
        let
          baseurl = "diffumist.me";
        in
        {
          noboard-tyo = {
            endpoint = "tyo-0.${baseurl}";
            ipv4 = "10.203.0.2";
            ipv6 = "fd42:203::2";
            publicKey = "MCowBQYDK2VwAyEAxaxg3eSL5D7leJWSY3wTVCfBuGZHNXRA7I8iqTCJQfY=";
          };
          wawo-hkg = {
            endpoint = "hkg-0.${baseurl}";
            ipv4 = "10.203.0.3";
            ipv6 = "fd42:203::3";
            publicKey = "MCowBQYDK2VwAyEA5W61PykXaGk/o6hkTbFhO/kGeu+Vyj9Rnx+i2IkUw5E=";
          };
          vpstown-hkg = {
            endpoint = "hkg-1.${baseurl}";
            ipv4 = "10.203.0.4";
            ipv6 = "fd42:203::4";
            publicKey = "MCowBQYDK2VwAyEAb36LDpzA0a54vXQwpmP4RdDG0GJMV5Xw2KZbuPZC+Rg=";
          };
          liteserver-ams = {
            endpoint = "ams-0.${baseurl}";
            ipv4 = "10.203.0.11";
            ipv6 = "fd42:203::11";
            publicKey = "MCowBQYDK2VwAyEAHWD6/iFFNulDjkJ+RnYtdpc5XuuQNg0h83ETEjxuR/I=";
          };
          netcup-nue = {
            endpoint = "nue-0.${baseurl}";
            ipv4 = "10.203.0.12";
            ipv6 = "fd42:203::12";
            publicKey = "MCowBQYDK2VwAyEANQX80uFK9lpujZVGJumGx5MoqGOfrpjPynBGXuVnhHY=";
          };
          rabisu-tur = {
            endpoint = "tur-0.${baseurl}";
            ipv4 = "10.203.0.13";
            ipv6 = "fd42:203::13";
            publicKey = "MCowBQYDK2VwAyEAoCrm/HrKymXZ06qH1UY6TsNqVQ8TASnM+LJ/jqtNBJM=";
          };
          dedirock-lax = {
            endpoint = "lax-0.${baseurl}";
            ipv4 = "10.203.0.21";
            ipv6 = "fd42:203::21";
            publicKey = "MCowBQYDK2VwAyEA7HDRa9C8RhgvI+G4l+s4pAPaezQezPskA9e0DTIlCZ0=";
          };
          hostdzire-sfo = {
            endpoint = "sjc-0.${baseurl}";
            ipv4 = "10.203.0.22";
            ipv6 = "fd42:203::22";
            publicKey = "MCowBQYDK2VwAyEA5bSezCNGCPGbcjwwRBT8at2v7xvotEAJ+l9DS8bfMRo=";
          };
          vmrack-lax = {
            endpoint = "lax-1.${baseurl}";
            ipv4 = "10.203.0.23";
            ipv6 = "fd42:203::23";
            publicKey = "MCowBQYDK2VwAyEAoJqu1kceg0UIsqlVHkkBkWKmoH6qC73hvm7e1lAPTbg=";
          };
          netcup-mnz = {
            endpoint = "mnz-0.${baseurl}";
            ipv4 = "10.203.0.24";
            ipv6 = "fd42:203::24";
            publicKey = "MCowBQYDK2VwAyEA36Mkx/5pjnVLKh4HJ9uh3qQNuDCXzO1phlD4DEd8ES0=";
          };
          cloudnium-lax = {
            endpoint = "lax-2.${baseurl}";
            ipv4 = "10.203.0.25";
            ipv6 = "fd42:203::25";
            publicKey = "MCowBQYDK2VwAyEAKUx+lmypr6aJSZSINXsTNSgaFAFJ0c3f3H2w2V4fWBI=";
          };
          moecloud-sjc = {
            endpoint = "sjc-1.${baseurl}";
            ipv4 = "10.203.0.26";
            ipv6 = "fd42:203::26";
            publicKey = "MCowBQYDK2VwAyEAUorS8qi1XuWUjGr7h+ZJ1t93KwiqwfueydSFvZY2EOo=";
          };
          vmiss-lax = {
            endpoint = "lax-3.${baseurl}";
            ipv4 = "10.203.0.27";
            ipv6 = "fd42:203::27";
            publicKey = "MCowBQYDK2VwAyEAdfZipMMgZ+B+zKXUHBQ+M/fQ6qEPmj1a/gTgHZhxdqY=";
          };
          google-west = {
            endpoint = "pdx-0.${baseurl}";
            ipv4 = "10.203.0.30";
            ipv6 = "fd42:203::30";
            publicKey = "MCowBQYDK2VwAyEAZ9klOv0f3TuOZiJ4Ie+YkApNjoZDOvic5m5YOkekfzM=";
          };
          google-east = {
            endpoint = "chs-0.${baseurl}";
            ipv4 = "10.203.0.31";
            ipv6 = "fd42:203::31";
            publicKey = "MCowBQYDK2VwAyEAqqz6YqgH6wRBhFrpKyUW5oVuBZnTjrAREPc3PqnCaos=";
          };
        };
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Ed25519 PKCS#8 PEM private key; defaults to the ranet_private_key SOPS secret.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = lib.allUnique (lib.mapAttrsToList (_: node: node.ipv4) cfg.nodes);
          message = "ranet IPv4 addresses must be unique.";
        }
        {
          assertion = lib.allUnique (lib.mapAttrsToList (_: node: node.ipv6) cfg.nodes);
          message = "ranet IPv6 addresses must be unique.";
        }
      ];
    }

    (lib.mkIf enabled {
      sops.secrets = lib.mkIf (cfg.privateKeyFile == null) { ranet_private_key = { }; };

      # swanctl --list-sas is the first thing to run when a peer is unreachable.
      environment.systemPackages = [ config.services.strongswan-swanctl.package ];

      networking.firewall.allowedUDPPorts = [ port ];
      my.networking.usedUDPPorts.ranet = port;

      # The overlay is host-to-host only. Nothing may be routed into or out of
      # it, which keeps DN42 peers and containers off the management plane.
      networking.nftables.tables.ranet = {
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority filter; policy accept;
            iifname "${linkPrefix}*" drop
            oifname "${linkPrefix}*" drop
          }
        '';
      };

      # Holds the management addresses so services can bind them before any
      # tunnel is up.
      systemd.network.netdevs."20-${dummy}".netdevConfig = {
        Name = dummy;
        Kind = "dummy";
      };
      systemd.network.networks."20-${dummy}" = {
        matchConfig.Name = dummy;
        address = [
          "${local.ipv4}/32"
          "${local.ipv6}/128"
        ];
        linkConfig.RequiredForOnline = "no";
      };

      # Global networkd wait-online is disabled on servers and ranet has
      # RequiredForOnline=no, so wait specifically for the dummy interface to
      # finish configuring both management addresses before strongSwan or
      # services binding the management IP start.
      systemd.services.ranet-ready = {
        description = "Wait for ranet management addresses";
        after = [ "systemd-networkd.service" ];
        wants = [ "systemd-networkd.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --interface=${dummy}:routable --ipv4 --ipv6 --timeout=30";
        };
      };

      systemd.services.strongswan-swanctl = {
        after = [ "ranet-ready.service" ];
        wants = [ "ranet-ready.service" ];
      };

      services.strongswan-swanctl = {
        enable = true;
        # ranet runs IKE and ESP on the NAT-T port alone; 0 keeps charon off
        # UDP 500.
        #
        # charon loads every built plugin by default. With ranet's 0.0.0.0/0
        # traffic selectors farp would answer ARP for any address on the
        # provider LAN, so only the plugins this mesh uses are loaded.
        strongswan.extraConfig = ''
          charon {
            port = 0
            port_nat_t = ${toString port}
            load = random nonce openssl pem pkcs1 pkcs8 pubkey kdf kernel-netlink socket-default vici updown
          }
        '';
      };

      systemd.services.ranet = {
        description = "ranet management mesh";
        bindsTo = [ "strongswan-swanctl.service" ];
        after = [
          "network-online.target"
          "nss-lookup.target"
          "strongswan-swanctl.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        # Reload reconciles in place; a restart would drop every tunnel.
        reloadTriggers = [
          ranetConfig
          registry
        ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${ranet} up";
          ExecReload = "${ranet} up";
          ExecStop = "${ranet} down";
          Restart = "on-failure";
          RestartSec = 10;
        };
      };

      # ranet resolves endpoint names only when it runs, so re-run it to follow
      # DNS changes and to dial peers that were unresolvable or down.
      systemd.services.ranet-reload = {
        startAt = "*:0/15";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.systemd.package}/bin/systemctl reload-or-restart ranet.service";
        };
      };
    })
  ];
}
