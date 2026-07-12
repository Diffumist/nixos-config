{
  config,
  hostName,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.dn42.mesh;
  nodes = cfg.nodes;
  links = cfg.links;
  nodeNames = builtins.attrNames nodes;
  localNodeName = lib.findFirst (name: nodes.${name}.hostName == hostName) null nodeNames;
  linkNodes = link: lib.splitString "-" (lib.removePrefix "wg-" link.name);
  enabled = cfg.enable && localNodeName != null;
  localLinks = lib.filter (link: builtins.elem localNodeName (linkNodes link)) links;
  ibgpPeers = lib.filterAttrs (name: _: name != localNodeName) nodes;
  lookingGlassProxyPort = cfg.lookingGlassProxyPort;
  dn42KernelRoutingTable = 642;
  mainRoutingTable = 254;
  dn42RoutingPolicyRules = [
    # Keep the management mesh out of the DN42 full-table lookup.
    {
      Priority = 9000;
      To = "10.203.0.0/24";
      Table = mainRoutingTable;
    }
    {
      Priority = 9001;
      To = "fd42:203::/64";
      Table = mainRoutingTable;
    }
    {
      Priority = 10000;
      To = "10.0.0.0/8";
      Table = dn42KernelRoutingTable;
    }
    {
      Priority = 10001;
      To = "172.20.0.0/14";
      Table = dn42KernelRoutingTable;
    }
    {
      Priority = 10002;
      To = "172.31.0.0/16";
      Table = dn42KernelRoutingTable;
    }
    {
      Priority = 10003;
      To = "fd00::/8";
      Table = dn42KernelRoutingTable;
    }
  ];

  assertions =
    let
      nodeList = builtins.attrValues nodes;
      nodeHostNames = map (node: node.hostName) nodeList;
      nodeIPv4s = map (node: node.ipv4) nodeList;
      nodeIPv6s = map (node: node.ipv6) nodeList;
      linkNodeNames = lib.concatMap linkNodes links;
      linkNames = map (link: link.name) links;
      ports = map (link: link.port) links;
      v4s = lib.concatMap (link: [
        link.a4
        link.b4
      ]) links;
      v6s = lib.concatMap (link: [
        link.a6
        link.b6
      ]) links;
      lls = lib.concatMap (link: [
        link.aLinkLocal
        link.bLinkLocal
      ]) links;

      unique = xs: builtins.length xs == builtins.length (lib.unique xs);
    in
    [
      {
        assertion = unique nodeHostNames;
        message = "dn42 mesh node host names must be unique.";
      }
      {
        assertion = lib.all (name: builtins.hasAttr name nodes) linkNodeNames;
        message = "dn42 mesh links must reference existing node names.";
      }
      {
        assertion = unique nodeIPv4s;
        message = "dn42 mesh node IPv4 addresses must be unique.";
      }
      {
        assertion = unique nodeIPv6s;
        message = "dn42 mesh node IPv6 addresses must be unique.";
      }
      {
        assertion = unique linkNames;
        message = "dn42 mesh link names must be unique.";
      }
      {
        assertion = unique ports;
        message = "dn42 mesh WireGuard listen ports must be unique.";
      }
      {
        assertion = unique v4s;
        message = "dn42 mesh IPv4 addresses must be unique.";
      }
      {
        assertion = unique v6s;
        message = "dn42 mesh IPv6 addresses must be unique.";
      }
      {
        assertion = unique lls;
        message = "dn42 mesh link-local addresses must be unique.";
      }
      {
        assertion =
          cfg.lookingGlassAllowedNode == null || builtins.hasAttr cfg.lookingGlassAllowedNode nodes;
        message = "dn42 mesh lookingGlassAllowedNode must reference an existing node.";
      }
    ];

  linkSide =
    link:
    let
      endpoints = linkNodes link;
      a = builtins.elemAt endpoints 0;
      b = builtins.elemAt endpoints 1;
    in
    if a == localNodeName then
      {
        local4 = link.a4;
        local6 = link.a6;
        localLinkLocal = link.aLinkLocal;
        peer = nodes.${b};
      }
    else
      {
        local4 = link.b4;
        local6 = link.b6;
        localLinkLocal = link.bLinkLocal;
        peer = nodes.${a};
      };

  mkNetdev =
    link:
    let
      side = linkSide link;
    in
    lib.nameValuePair "20-${link.name}" {
      netdevConfig = {
        Name = link.name;
        Kind = "wireguard";
        MTUBytes = "1280";
      };
      wireguardConfig = {
        ListenPort = link.port;
        PrivateKeyFile = config.sops.secrets.dn42_wg_private_key.path;
      };
      wireguardPeers = [
        {
          PublicKey = side.peer.publicKey;
          Endpoint = "${side.peer.endpoint}:${toString link.port}";
          AllowedIPs = [
            "0.0.0.0/0"
            "::/0"
          ];
          PersistentKeepalive = 25;
        }
      ];
    };

  mkNetwork =
    link:
    let
      side = linkSide link;
    in
    lib.nameValuePair "20-${link.name}" {
      matchConfig.Name = link.name;
      address = [
        "${side.local4}/31"
        "${side.localLinkLocal}/64"
        "${side.local6}/127"
      ];
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
      };
    };
in
{
  options.my.services.dn42.mesh = {
    enable = lib.mkEnableOption "DN42 internal mesh";

    nodes = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Internal DN42 mesh nodes keyed by short node name.";
    };

    links = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Internal DN42 mesh WireGuard links.";
    };

    asn = lib.mkOption {
      type = lib.types.ints.u32;
      description = "Local DN42 ASN.";
    };

    ipv4Pool = lib.mkOption {
      type = lib.types.str;
      description = "Local DN42 IPv4 pool.";
    };

    ipv6Pool = lib.mkOption {
      type = lib.types.str;
      description = "Local DN42 IPv6 pool.";
    };

    roaRegistry = lib.mkOption {
      type = lib.types.path;
      description = "DN42 registry source for ROA generation.";
    };

    flapDamping.serverAddress = lib.mkOption {
      type = lib.types.str;
      description = "Central FlapAlerted address.";
    };

    lookingGlassProxyPort = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "bird-lg proxy port exposed on DN42 mesh links.";
    };

    lookingGlassAllowedNode = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Extra mesh node allowed to query this bird-lg proxy.";
    };
  };

  config = lib.mkIf enabled (
    let
      node = nodes.${localNodeName};
    in
    {
      inherit assertions;

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.rp_filter" = lib.mkForce 0;
        "net.ipv4.conf.default.rp_filter" = lib.mkForce 0;
        "net.ipv4.conf.*.rp_filter" = lib.mkForce 0;
      };

      sops.secrets.dn42_wg_private_key = {
        owner = "systemd-network";
        mode = "0400";
      };

      my.services.dn42.flapDamping = {
        enable = true;
        runServer = lib.mkDefault false;
        serverAddress = cfg.flapDamping.serverAddress;
      };

      networking.firewall = {
        allowedUDPPorts = map (link: link.port) localLinks;
        checkReversePath = false;
        interfaces = lib.listToAttrs (
          map (
            link:
            lib.nameValuePair link.name {
              allowedTCPPorts = [
                179
                lookingGlassProxyPort
              ];
            }
          ) localLinks
        );
      };

      networking.dn42 = {
        enable = true;
        asn = cfg.asn;

        ipv4 = {
          address = node.ipv4;
          pool = cfg.ipv4Pool;
        };

        ipv6 = {
          address = node.ipv6;
          pool = cfg.ipv6Pool;
        };

        roa = {
          enable = true;
          registry = cfg.roaRegistry;
        };

        kernel.routingTable = dn42KernelRoutingTable;

        ospf = {
          enable = true;
          interfaces = lib.listToAttrs (
            map (link: lib.nameValuePair link.name { openFirewall = true; }) localLinks
          );
        };

        ibgp = {
          enable = true;
          peers = lib.mapAttrs (_: peer: { address = peer.ipv6; }) ibgpPeers;
        };
      };

      services.bird = {
        enable = true;
        package = pkgs.bird2;
        autoReload = true;
        config = lib.mkAfter ''
          protocol direct dn42_direct_v4 {
            ipv4;
            interface "dn42-dummy";
          }
        '';
      };

      services.bird-lg.proxy = {
        enable = true;
        allowedIPs = [
          "127.0.0.1"
        ]
        ++ lib.optional (cfg.lookingGlassAllowedNode != null) nodes.${cfg.lookingGlassAllowedNode}.ipv4;
        listenAddresses = [
          "127.0.0.1:${toString lookingGlassProxyPort}"
          "${node.ipv4}:${toString lookingGlassProxyPort}"
        ];
      };

      systemd.services.frr.enable = lib.mkForce false;

      security.pki.certificateFiles = [
        "${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt"
      ];

      systemd.network.netdevs = lib.listToAttrs (map mkNetdev localLinks);
      systemd.network.networks = (lib.listToAttrs (map mkNetwork localLinks)) // {
        "10-dn42-dummy".routingPolicyRules = dn42RoutingPolicyRules;
      };

    }
  );
}
