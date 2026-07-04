{
  config,
  inputs,
  hostName,
  lib,
  pkgs,
  ...
}:
let
  baseurl = "diffumist.me";
  nodes = {
    # liteserver
    ams0 = {
      hostName = "liteserver";
      endpoint = "ams-0.${baseurl}";
      ipv4 = "172.22.64.65";
      ipv6 = "fd22:1056:95a4:1::1";
      publicKey = "25KV0x3WcKCCg7HcTVAB+27LrMpIfrZl05hgX5QGnzU=";
    };
    # hostdzire
    sjc0 = {
      hostName = "hostdzire";
      endpoint = "sjc-0.${baseurl}";
      ipv4 = "172.22.64.66";
      ipv6 = "fd22:1056:95a4:2::1";
      publicKey = "byljo5bFvup+YtQbae/m3ReiWFwCHFN+CAWinzirvQo=";
    };
    # dedirock
    lax0 = {
      hostName = "dedirock";
      endpoint = "lax-0.${baseurl}";
      ipv4 = "172.22.64.67";
      ipv6 = "fd22:1056:95a4:3::1";
      publicKey = "viwkjXKilMxRupylyaqMHrZylzhW80+NypBNvVf/0G8=";
    };
    # geelinx-jp
    tyo0 = {
      hostName = "geelinx-jp";
      endpoint = "tyo-0.${baseurl}";
      ipv4 = "172.22.64.68";
      ipv6 = "fd22:1056:95a4:4::1";
      publicKey = "KD/4v/fKXWXzvt2z3rxJN31QJIfw/cRSBq0nJppbYG4=";
    };
    # wawo
    hkg0 = {
      hostName = "wawo";
      endpoint = "hkg-0.${baseurl}";
      ipv4 = "172.22.64.69";
      ipv6 = "fd22:1056:95a4:5::1";
      publicKey = "3anHMuAw/sDlRCN7xoRUf1l4SdAu0Rfl2pqpeJtJn3Y=";
    };
  };
  flapalertedAddress = "fd22:1056:95a4:4::1179";

  links = [
    {
      name = "wg-ams0-sjc0";
      port = 42420;
      a4 = "192.168.242.2";
      b4 = "192.168.242.3";
      a6 = "fd22:1056:95a4:ffff::2";
      b6 = "fd22:1056:95a4:ffff::3";
      aLinkLocal = "fe80::642:2";
      bLinkLocal = "fe80::642:3";
    }
    {
      name = "wg-ams0-lax0";
      port = 42422;
      a4 = "192.168.242.4";
      b4 = "192.168.242.5";
      a6 = "fd22:1056:95a4:ffff::4";
      b6 = "fd22:1056:95a4:ffff::5";
      aLinkLocal = "fe80::642:4";
      bLinkLocal = "fe80::642:5";
    }
    {
      name = "wg-sjc0-lax0";
      port = 42425;
      a4 = "192.168.242.8";
      b4 = "192.168.242.9";
      a6 = "fd22:1056:95a4:ffff::8";
      b6 = "fd22:1056:95a4:ffff::9";
      aLinkLocal = "fe80::642:8";
      bLinkLocal = "fe80::642:9";
    }
    {
      name = "wg-sjc0-tyo0";
      port = 42426;
      a4 = "192.168.242.10";
      b4 = "192.168.242.11";
      a6 = "fd22:1056:95a4:ffff::10";
      b6 = "fd22:1056:95a4:ffff::11";
      aLinkLocal = "fe80::642:10";
      bLinkLocal = "fe80::642:11";
    }
    {
      name = "wg-lax0-tyo0";
      port = 42429;
      a4 = "192.168.242.12";
      b4 = "192.168.242.13";
      a6 = "fd22:1056:95a4:ffff::12";
      b6 = "fd22:1056:95a4:ffff::13";
      aLinkLocal = "fe80::642:12";
      bLinkLocal = "fe80::642:13";
    }
    {
      name = "wg-ams0-hkg0";
      port = 42430;
      a4 = "192.168.242.14";
      b4 = "192.168.242.15";
      a6 = "fd22:1056:95a4:ffff::14";
      b6 = "fd22:1056:95a4:ffff::15";
      aLinkLocal = "fe80::642:14";
      bLinkLocal = "fe80::642:15";
    }
    {
      name = "wg-lax0-hkg0";
      port = 42431;
      a4 = "192.168.242.16";
      b4 = "192.168.242.17";
      a6 = "fd22:1056:95a4:ffff::16";
      b6 = "fd22:1056:95a4:ffff::17";
      aLinkLocal = "fe80::642:16";
      bLinkLocal = "fe80::642:17";
    }
    {
      name = "wg-tyo0-hkg0";
      port = 42432;
      a4 = "192.168.242.18";
      b4 = "192.168.242.19";
      a6 = "fd22:1056:95a4:ffff::18";
      b6 = "fd22:1056:95a4:ffff::19";
      aLinkLocal = "fe80::642:18";
      bLinkLocal = "fe80::642:19";
    }
  ];

  nodeNames = builtins.attrNames nodes;
  localNodeName = lib.findFirst (name: nodes.${name}.hostName == hostName) null nodeNames;
  linkNodes = link: lib.splitString "-" (lib.removePrefix "wg-" link.name);
  enabled = localNodeName != null;
  localLinks = lib.filter (link: builtins.elem localNodeName (linkNodes link)) links;
  ibgpPeers = lib.filterAttrs (name: _: name != localNodeName) nodes;
  lookingGlassProxyPort = 8000;

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
        serverAddress = flapalertedAddress;
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
        asn = 4242420642;

        ipv4 = {
          address = node.ipv4;
          pool = "172.22.64.64/27";
        };

        ipv6 = {
          address = node.ipv6;
          pool = "fd22:1056:95a4::/48";
        };

        roa = {
          enable = true;
          registry = inputs.dn42-registry;
        };

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
          nodes.lax0.ipv4
        ];
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
      systemd.network.networks = lib.listToAttrs (map mkNetwork localLinks);

    }
  );
}
