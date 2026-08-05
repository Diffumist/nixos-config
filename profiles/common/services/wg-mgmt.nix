{
  config,
  hostName,
  lib,
  ...
}:
let
  baseurl = "diffumist.me";
  interface = "wg-mgmt";
  listenPort = 44242;
  nodes = {
    noboard-tyo = {
      endpoint = "tyo-0.${baseurl}";
      ipv4 = "10.203.0.2";
      ipv6 = "fd42:203::2";
      publicKey = "cmYopEooVzPXVheJRUciRbmMK38dTGR0yvXXMUPBwwY=";
    };
    wawo-hkg = {
      endpoint = "hkg-0.${baseurl}";
      ipv4 = "10.203.0.3";
      ipv6 = "fd42:203::3";
      publicKey = "/kMulSNnzMkdoi1WslQuZxuK9SKu7goI+WIGGIJ0Qik=";
    };
    liteserver-ams = {
      endpoint = "ams-0.${baseurl}";
      ipv4 = "10.203.0.11";
      ipv6 = "fd42:203::11";
      publicKey = "D98b1mSOWpTz49IgzFgZ0htuux3HUn0BxylnKgr77H8=";
    };
    dedirock-lax = {
      endpoint = "lax-0.${baseurl}";
      ipv4 = "10.203.0.21";
      ipv6 = "fd42:203::21";
      publicKey = "O9eaz2AHPgSDxTVs+/iaUAno+SmnIDUI4SE1BGD6FiQ=";
    };
    vmiss-lax = {
      endpoint = "lax-1.${baseurl}";
      ipv4 = "10.203.0.22";
      ipv6 = "fd42:203::22";
      publicKey = "O9eaz2AHPgSDxTVs+/iaUAno+SmnIDUI4SE1BGD6FiQ=";
    };
    vmrack-lax = {
      endpoint = "lax-2.${baseurl}";
      ipv4 = "10.203.0.23";
      ipv6 = "fd42:203::23";
      publicKey = "rDjdsHMYBbmMx1s/5/DNWQJu4CWBqRZL7IUrGznC0XQ=";
    };
    colocrossing-lax = {
      endpoint = "lax-3.${baseurl}";
      ipv4 = "10.203.0.24";
      ipv6 = "fd42:203::24";
      publicKey = "nL/tNYad/CsHP/iiqI/tXMdIsoSqDMfozbDudOkspwY=";
    };
    google-west = {
      endpoint = "pdx-0.${baseurl}";
      ipv4 = "10.203.0.26";
      ipv6 = "fd42:203::26";
      publicKey = "Zs43Po/Y10I9cwoy+zOTFcAWAdGgA+Q95YKPOOeRiio=";
    };
    hostdzire-sfo = {
      endpoint = "sjc-0.${baseurl}";
      ipv4 = "10.203.0.31";
      ipv6 = "fd42:203::31";
      publicKey = "6x/Qcn7yghNo7AD6ckKFvTpqW9EhuzzhC0qVXpup3HI=";
    };
    nosla-sjc = {
      endpoint = "sjc-1.${baseurl}";
      ipv4 = "10.203.0.32";
      ipv6 = "fd42:203::32";
      publicKey = "CsizRoeV1LdnEl8hGg8Dp/1GD1WRuY/8uFz76H/+3TQ=";
    };
    raksmart-sjc = {
      endpoint = "sjc-2.${baseurl}";
      ipv4 = "10.203.0.33";
      ipv6 = "fd42:203::33";
      publicKey = "U3+Vwby1YV5mGBndaiOzUl5NZ4ORhIXB6p7nrKP/0nU=";
    };
    geelinx-ord = {
      endpoint = "ord-0.${baseurl}";
      ipv4 = "10.203.0.41";
      ipv6 = "fd42:203::41";
      publicKey = "iSa5qFW8m42DIJBhtMqlT2DWdYF/ODauxHQOaKnJXDw=";
    };
    google-east = {
      endpoint = "chs-0.${baseurl}";
      ipv4 = "10.203.0.42";
      ipv6 = "fd42:203::42";
      publicKey = "C9fnOkg9z7rqLBk75W+XQdzdc42DbmfULDCgoZ04BRI=";
    };
  };

  coreLinks = [
    [
      "hostdzire-sfo"
      "noboard-tyo"
    ]
    [
      "hostdzire-sfo"
      "liteserver-ams"
    ]
    [
      "hostdzire-sfo"
      "geelinx-ord"
    ]
    [
      "hostdzire-sfo"
      "dedirock-lax"
    ]
    [
      "noboard-tyo"
      "liteserver-ams"
    ]
    [
      "noboard-tyo"
      "geelinx-ord"
    ]
    [
      "noboard-tyo"
      "dedirock-lax"
    ]
    [
      "geelinx-ord"
      "liteserver-ams"
    ]
    [
      "geelinx-ord"
      "dedirock-lax"
    ]
    [
      "liteserver-ams"
      "dedirock-lax"
    ]
  ];

  regionalLinks = {
    hostdzire-sfo = [
      "raksmart-sjc"
      "nosla-sjc"
      "google-west"
    ];
    dedirock-lax = [
      "vmiss-lax"
      "vmrack-lax"
      "colocrossing-lax"
    ];
    noboard-tyo = [
      "wawo-hkg"
    ];
    geelinx-ord = [ "google-east" ];
  };

  enabled = builtins.hasAttr hostName nodes;
  unique = xs: builtins.length xs == builtins.length (lib.unique xs);
  mkPair = pair: {
    a = builtins.elemAt pair 0;
    b = builtins.elemAt pair 1;
  };
  linkPairs =
    map mkPair coreLinks
    ++ lib.concatLists (
      lib.mapAttrsToList (
        a:
        map (b: {
          inherit a b;
        })
      ) regionalLinks
    );
  linkKey = link: "${link.a}->${link.b}";
  localLinks = lib.filter (link: link.a == hostName || link.b == hostName) linkPairs;
  linkPeer = link: nodes.${if link.a == hostName then link.b else link.a};
in
{
  config = lib.mkIf enabled (
    let
      node = nodes.${hostName};
      peers = map linkPeer localLinks;
    in
    {
      assertions = [
        {
          assertion = unique (map (n: n.ipv4) (lib.attrValues nodes));
          message = "wg-mgmt IPv4 addresses must be unique.";
        }
        {
          assertion = unique (map (n: n.ipv6) (lib.attrValues nodes));
          message = "wg-mgmt IPv6 addresses must be unique.";
        }
        {
          assertion = lib.all (
            link: builtins.hasAttr link.a nodes && builtins.hasAttr link.b nodes
          ) linkPairs;
          message = "wg-mgmt links must reference existing nodes.";
        }
        {
          assertion = unique (map linkKey linkPairs);
          message = "wg-mgmt links must be unique.";
        }
        {
          assertion = localLinks != [ ];
          message = "wg-mgmt enabled nodes must have at least one link.";
        }
      ];

      sops.secrets.wg_mgmt_private_key = {
        owner = "systemd-network";
        mode = "0400";
      };

      networking.firewall.allowedUDPPorts = [ listenPort ];

      systemd.network.netdevs."20-${interface}" = {
        netdevConfig = {
          Name = interface;
          Kind = "wireguard";
        };
        wireguardConfig = {
          ListenPort = listenPort;
          PrivateKeyFile = config.sops.secrets.wg_mgmt_private_key.path;
        };
        wireguardPeers = map (peer: {
          PublicKey = peer.publicKey;
          Endpoint = "${peer.endpoint}:${toString listenPort}";
          AllowedIPs = [
            "${peer.ipv4}/32"
            "${peer.ipv6}/128"
          ];
          PersistentKeepalive = 25;
        }) peers;
      };

      systemd.network.networks."20-${interface}" = {
        matchConfig.Name = interface;
        address = [
          "${node.ipv4}/32"
          "${node.ipv6}/128"
        ];
        linkConfig.RequiredForOnline = "no";
        networkConfig = {
          IPv6AcceptRA = false;
          LinkLocalAddressing = "no";
        };
      };
    }
  );
}
