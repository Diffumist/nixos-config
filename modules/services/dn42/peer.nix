{
  config,
  helpers,
  hostName,
  lib,
  ...
}:
let
  inherit (helpers.network) formatHostPort;
  cfg = config.my.services.dn42;
  dn42 = config.networking.dn42;
  peers = lib.attrValues cfg.peers;
  localNode = lib.findFirst (node: node.hostName == hostName) null (lib.attrValues cfg.mesh.nodes);
  lines = lib.concatStringsSep "\n";

  # Well-known, DN42 standard (64511:*), and AS4242420642 large community helpers.
  communityDefinitions = [
    "define OWN_ASN = ${toString dn42.asn};"
    "define COMM_GRACEFUL_SHUTDOWN = (65535, 0);"
    "define DN42_NODE_ID = ${toString localNode.id};"
    "define DN42_NODE_REGION = ${toString localNode.region};"
    "define DN42_NODE_COUNTRY = ${toString localNode.country};"
  ]
  ++ lib.optional cfg.flapDamping.enable "define COMM_FLAPPING = (64511, 65282);"
  ++ [
    ""
    ''
      function dn42_update_crypto(int link_crypto) {
        bgp_community.add((64511, link_crypto));
        if (64511, 31) ~ bgp_community then bgp_community.delete([(64511, 32..36)]);
        else if (64511, 32) ~ bgp_community then bgp_community.delete([(64511, 33..36)]);
        else if (64511, 33) ~ bgp_community then bgp_community.delete([(64511, 34..36)]);
        else if (64511, 34) ~ bgp_community then bgp_community.delete([(64511, 35..36)]);
        else if (64511, 35) ~ bgp_community then bgp_community.delete((64511, 36));
      }

      function dn42_update_topology(int link_topology) {
        bgp_community.add((64511, link_topology));
        if (64511, 89) ~ bgp_community then bgp_community.delete([(64511, 81..88)]);
        else if (64511, 85) ~ bgp_community then bgp_community.delete([(64511, 81..84)]);
        else if (64511, 84) ~ bgp_community then bgp_community.delete([(64511, 81..83)]);
        else if (64511, 83) ~ bgp_community then bgp_community.delete([(64511, 81..82)]);
        else if (64511, 82) ~ bgp_community then bgp_community.delete((64511, 81));
      }
    ''
  ];

  importCommon = lines (
    [
      "function dn42_ebgp_import_common() {"
    ]
    ++ lib.optional cfg.flapDamping.enable "  bgp_community.delete(COMM_FLAPPING);"
    ++ [
      "  bgp_large_community.delete([(OWN_ASN, 10..12, *)]);"
      "  dn42_update_crypto(34);"
      "  dn42_update_topology(83);"
      "  bgp_large_community.add((OWN_ASN, 10, DN42_NODE_ID));"
      "  bgp_large_community.add((OWN_ASN, 11, DN42_NODE_REGION));"
      "  bgp_large_community.add((OWN_ASN, 12, DN42_NODE_COUNTRY));"
      "  if (OWN_ASN, 200, 50) ~ bgp_large_community then bgp_local_pref = 50;"
      "  else if (OWN_ASN, 200, 80) ~ bgp_large_community then bgp_local_pref = 80;"
      "  else if (OWN_ASN, 200, 90) ~ bgp_large_community then bgp_local_pref = 90;"
      "  if COMM_GRACEFUL_SHUTDOWN ~ bgp_community then bgp_local_pref = 0;"
      "}"
    ]
  );

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
        "  dn42_ebgp_import_common();"
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

  exportFunction = lines (
    [
      "function dn42_ebgp_export(int peer_asn) -> bool"
      "int prepend_count;"
      "{"
      "  if source = RTS_STATIC then {"
      "    bgp_community.add((64511, DN42_NODE_REGION));"
      "    bgp_community.add((64511, DN42_NODE_COUNTRY));"
      "    bgp_large_community.add((OWN_ASN, 10, DN42_NODE_ID));"
      "    bgp_large_community.add((OWN_ASN, 11, DN42_NODE_REGION));"
      "    bgp_large_community.add((OWN_ASN, 12, DN42_NODE_COUNTRY));"
      "    dn42_update_crypto(34);"
      "    dn42_update_topology(83);"
      "    return true;"
      "  }"
      "  if source = RTS_BGP then {"
    ]
    ++ lib.optional cfg.flapDamping.enable "    if COMM_FLAPPING ~ bgp_community then return false;"
    ++ [
      "    if (OWN_ASN, 0, 0) ~ bgp_large_community then return false;"
      "    if peer_asn > 0 && (OWN_ASN, 0, peer_asn) ~ bgp_large_community then return false;"
      "    if (OWN_ASN, 1000, DN42_NODE_REGION) ~ bgp_large_community then return false;"
      "    if (OWN_ASN, 1001, DN42_NODE_ID) ~ bgp_large_community then return false;"
      "    prepend_count = 0;"
      "    if peer_asn > 0 && (OWN_ASN, 103, peer_asn) ~ bgp_large_community then prepend_count = 3;"
      "    else if peer_asn > 0 && (OWN_ASN, 102, peer_asn) ~ bgp_large_community then prepend_count = 2;"
      "    else if peer_asn > 0 && (OWN_ASN, 101, peer_asn) ~ bgp_large_community then prepend_count = 1;"
      "    else if (OWN_ASN, 1103, DN42_NODE_REGION) ~ bgp_large_community then prepend_count = 3;"
      "    else if (OWN_ASN, 1102, DN42_NODE_REGION) ~ bgp_large_community then prepend_count = 2;"
      "    else if (OWN_ASN, 1101, DN42_NODE_REGION) ~ bgp_large_community then prepend_count = 1;"
      "    else if (OWN_ASN, 103, 0) ~ bgp_large_community then prepend_count = 3;"
      "    else if (OWN_ASN, 102, 0) ~ bgp_large_community then prepend_count = 2;"
      "    else if (OWN_ASN, 101, 0) ~ bgp_large_community then prepend_count = 1;"
      "    if prepend_count >= 1 then bgp_path.prepend(OWN_ASN);"
      "    if prepend_count >= 2 then bgp_path.prepend(OWN_ASN);"
      "    if prepend_count >= 3 then bgp_path.prepend(OWN_ASN);"
      "    bgp_large_community.delete(["
      "      (OWN_ASN, 0, *),"
      "      (OWN_ASN, 101..103, *),"
      "      (OWN_ASN, 200, *),"
      "      (OWN_ASN, 1000..1001, *),"
      "      (OWN_ASN, 1101..1103, *)"
      "    ]);"
      "    dn42_update_crypto(34);"
      "    dn42_update_topology(83);"
      "    return true;"
      "  }"
      ""
      "  return false;"
      "}"
    ]
  );

  # Compatibility wrappers for any runtime /run/autopeer/bird/*.conf written
  # before the template switched to `export where dn42_ebgp_export(<asn>)`.
  legacyExportWrappers = ''
    filter dn42_ebgp4_export {
      if dn42_ebgp_export(0) then accept;
      reject;
    }

    filter dn42_ebgp6_export {
      if dn42_ebgp_export(0) then accept;
      reject;
    }
  '';

  filterBlocks = [
    importCommon
    ""
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
    exportFunction
    ""
    legacyExportWrappers
  ];
  birdFilters = lines (communityDefinitions ++ filterBlocks);

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
            Endpoint = formatHostPort peer.endpoint peer.peerPort;
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
        export where dn42_ebgp_export(${toString peer.asn});
        export table on;
      };
      ipv6 {
        preference 200;
        next hop self ebgp;
        import filter dn42_ebgp6_import;
        export where dn42_ebgp_export(${toString peer.asn});
        export table on;
      };
      neighbor ${peer.peerLinkLocal}%'${peer.interface}' as ${toString peer.asn};
    }
  '';
in
{
  options = {
    # What the Bird side of a peer is made of, for whatever else brings up
    # peers (the autopeer agent's runtime ones), so they cannot drift from
    # the declared ones.
    my.services.dn42.peerBird = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.raw;
      default = {
        filters = birdFilters;
        protocol = mkBird;
      };
    };

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

    my.networking = {
      usedTCPPorts.bird-bgp = 179;
      usedUDPPorts = lib.listToAttrs (
        map (peer: lib.nameValuePair "dn42-peer/${peer.interface}" peer.listenPort) peers
      );
    };

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
