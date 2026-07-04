{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.dn42;
  dn42 = config.networking.dn42;
  peers = lib.attrValues cfg.peers;
  lines = lib.concatStringsSep "\n";
  mkImportFilter =
    {
      name,
      pool,
      roaTable,
      flapRoaTable,
    }:
    lines (
      [
        "filter ${name} {"
        "  if net ~ [ ${pool}+ ] then reject;"
        "  if roa_check(${roaTable}) != ROA_VALID then reject;"
      ]
      ++ lib.optionals cfg.flapDamping.enable [
        "  if roa_check(${flapRoaTable}, net, bgp_path.last) = ROA_INVALID then {"
        "    bgp_community.add(COMM_FLAPPING);"
        "    bgp_local_pref = 0;"
        "  }"
      ]
      ++ [
        "  accept;"
        "}"
      ]
    );
  mkExportFilter =
    name:
    lines (
      [
        "filter ${name} {"
        "  if source = RTS_STATIC then accept;"
        "  if source = RTS_BGP then {"
      ]
      ++ lib.optional cfg.flapDamping.enable "    if COMM_FLAPPING ~ bgp_community then reject;"
      ++ [
        "    accept;"
        "  }"
        ""
        "  reject;"
        "}"
      ]
    );
  flapDefinitions = lib.optionals cfg.flapDamping.enable [
    "define COMM_FLAPPING = (64511, 65282);"
    ""
  ];
  filterBlocks = [
    (mkImportFilter {
      name = "dn42_ebgp4_import";
      pool = dn42.ipv4.pool;
      roaTable = "dn42_roa4";
      flapRoaTable = "roa_flap_v4";
    })
    ""
    (mkImportFilter {
      name = "dn42_ebgp6_import";
      pool = dn42.ipv6.pool;
      roaTable = "dn42_roa6";
      flapRoaTable = "roa_flap_v6";
    })
    ""
    (mkExportFilter "dn42_ebgp4_export")
    ""
    (mkExportFilter "dn42_ebgp6_export")
  ];
  birdFilters = lines (flapDefinitions ++ filterBlocks);

  # eBGP peers run over WireGuard, with the BGP session on IPv6 link-local
  # (multiprotocol / extended-next-hop). Relies on dn42.nix for the dn42_peer
  # bird template, services.bird, and the dn42_wg_private_key sops secret.
  mkNetdev =
    peer:
    lib.nameValuePair "20-${peer.interface}" {
      netdevConfig = {
        Name = peer.interface;
        Kind = "wireguard";
        MTUBytes = toString peer.mtu;
      };
      wireguardConfig = {
        ListenPort = peer.listenPort;
        PrivateKeyFile = peer.privateKeyFile;
        RouteTable = "off";
      };
      wireguardPeers = [
        (
          {
            PublicKey = peer.publicKey;
            AllowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            PersistentKeepalive = 25;
          }
          // lib.optionalAttrs (peer.endpoint != null) {
            Endpoint = "${peer.endpoint}:${toString peer.peerPort}";
          }
        )
      ];
    };

  mkNetwork =
    peer:
    lib.nameValuePair "20-${peer.interface}" {
      matchConfig.Name = peer.interface;
      address = [ "${peer.localLinkLocal}/64" ];
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
      };
    };

  mkBird = peer: ''
    protocol bgp dn42_${lib.replaceStrings [ "-" ] [ "_" ] peer.interface} from dn42_peer {
      enable extended messages on;

      ipv4 {
        preference 200;
        next hop self ebgp;
        extended next hop on;
        import filter dn42_ebgp4_import;
        export filter dn42_ebgp4_export;
        export table on;
      };
      ipv6 {
        preference 200;
        next hop self ebgp;
        import filter dn42_ebgp6_import;
        export filter dn42_ebgp6_export;
        export table on;
      };
      neighbor ${peer.peerLinkLocal}%'${peer.interface}' as ${toString peer.asn};
    }
  '';
in
{
  options = {
    my.services.dn42.peers = lib.mkOption {
      default = { };
      description = ''
        External dn42 eBGP peers (other ASes), each over its own WireGuard tunnel.
        Port convention "2 + last 4 of peer ASN":
          - peerPort   = 2 + our ASN last 4 (we dial this)
          - listenPort = 2 + their ASN last 4 (they dial this)
      '';
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              interface = lib.mkOption {
                type = lib.types.str;
                default = "wg-${name}";
                description = "WireGuard interface name.";
              };
              asn = lib.mkOption {
                type = lib.types.ints.u32;
                description = "Peer ASN.";
              };
              listenPort = lib.mkOption {
                type = lib.types.port;
                description = "Our WireGuard listen port (the peer dials this).";
              };
              endpoint = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Peer WireGuard endpoint host (without port).";
              };
              peerPort = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = null;
                description = "Peer WireGuard port (we dial this).";
              };
              publicKey = lib.mkOption {
                type = lib.types.str;
                description = "Peer WireGuard public key.";
              };
              peerLinkLocal = lib.mkOption {
                type = lib.types.str;
                description = "Peer IPv6 link-local address for the BGP session.";
              };
              localLinkLocal = lib.mkOption {
                type = lib.types.str;
                default = "fe80::642";
                description = "Our IPv6 link-local on the peering interface (ASN-derived).";
              };
              mtu = lib.mkOption {
                type = lib.types.ints.positive;
                default = 1420;
                description = "Tunnel MTU.";
              };
              privateKeyFile = lib.mkOption {
                type = lib.types.path;
                default = config.sops.secrets.dn42_wg_private_key.path;
                defaultText = lib.literalExpression "config.sops.secrets.dn42_wg_private_key.path";
                description = "WireGuard private key file.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf (cfg.peers != { }) {
    networking.firewall.allowedUDPPorts = map (peer: peer.listenPort) peers;

    # eBGP runs over TCP/179 inside the WireGuard tunnel; allow it per peer
    # interface only (not the whole host).
    networking.firewall.interfaces = lib.listToAttrs (
      map (peer: lib.nameValuePair peer.interface { allowedTCPPorts = [ 179 ]; }) peers
    );

    services.bird.config = lib.mkAfter (
      lib.concatStringsSep "\n" ([ birdFilters ] ++ map mkBird peers)
    );

    systemd.network.netdevs = lib.listToAttrs (map mkNetdev peers);
    systemd.network.networks = lib.listToAttrs (map mkNetwork peers);
  };
}
