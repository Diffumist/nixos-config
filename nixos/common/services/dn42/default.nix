{
  config,
  inputs,
  hostName,
  lib,
  pkgs,
  ...
}:
let
  nodes = {
    liteserver = {
      endpoint = "ams-0.diffumist.me";
      ipv4 = "172.22.64.65";
      ipv6 = "fd22:1056:95a4:1::1";
      publicKey = "25KV0x3WcKCCg7HcTVAB+27LrMpIfrZl05hgX5QGnzU=";
    };
    hostdzire = {
      endpoint = "sjc-0.diffumist.me";
      ipv4 = "172.22.64.66";
      ipv6 = "fd22:1056:95a4:2::1";
      publicKey = "byljo5bFvup+YtQbae/m3ReiWFwCHFN+CAWinzirvQo=";
    };
    dedirock = {
      endpoint = "lax-0.diffumist.me";
      ipv4 = "172.22.64.67";
      ipv6 = "fd22:1056:95a4:3::1";
      publicKey = "viwkjXKilMxRupylyaqMHrZylzhW80+NypBNvVf/0G8=";
    };
    geelinx-jp = {
      endpoint = "tyo-0.diffumist.me";
      ipv4 = "172.22.64.68";
      ipv6 = "fd22:1056:95a4:4::1";
      publicKey = "KD/4v/fKXWXzvt2z3rxJN31QJIfw/cRSBq0nJppbYG4=";
    };
    wawo = {
      endpoint = "hkg-0.diffumist.me";
      ipv4 = "172.22.64.69";
      ipv6 = "fd22:1056:95a4:5::1";
      publicKey = "3anHMuAw/sDlRCN7xoRUf1l4SdAu0Rfl2pqpeJtJn3Y=";
    };
  };

  links = [
    {
      name = "wg-ams0-sjc0";
      port = 42420;
      a = "liteserver";
      b = "hostdzire";
      a6 = "fd22:1056:95a4:ffff::2";
      b6 = "fd22:1056:95a4:ffff::3";
      aLinkLocal = "fe80::642:2";
      bLinkLocal = "fe80::642:3";
    }
    {
      name = "wg-ams0-lax0";
      port = 42422;
      a = "liteserver";
      b = "dedirock";
      a6 = "fd22:1056:95a4:ffff::4";
      b6 = "fd22:1056:95a4:ffff::5";
      aLinkLocal = "fe80::642:4";
      bLinkLocal = "fe80::642:5";
    }
    {
      name = "wg-sjc0-lax0";
      port = 42425;
      a = "hostdzire";
      b = "dedirock";
      a6 = "fd22:1056:95a4:ffff::8";
      b6 = "fd22:1056:95a4:ffff::9";
      aLinkLocal = "fe80::642:8";
      bLinkLocal = "fe80::642:9";
    }
    {
      name = "wg-sjc0-tyo0";
      port = 42426;
      a = "hostdzire";
      b = "geelinx-jp";
      a6 = "fd22:1056:95a4:ffff::c";
      b6 = "fd22:1056:95a4:ffff::d";
      aLinkLocal = "fe80::642:c";
      bLinkLocal = "fe80::642:d";
    }
    {
      name = "wg-lax0-tyo0";
      port = 42429;
      a = "dedirock";
      b = "geelinx-jp";
      a6 = "fd22:1056:95a4:ffff::e";
      b6 = "fd22:1056:95a4:ffff::f";
      aLinkLocal = "fe80::642:e";
      bLinkLocal = "fe80::642:f";
    }
    {
      name = "wg-ams0-hkg0";
      port = 42430;
      a = "liteserver";
      b = "wawo";
      a6 = "fd22:1056:95a4:ffff::10";
      b6 = "fd22:1056:95a4:ffff::11";
      aLinkLocal = "fe80::642:10";
      bLinkLocal = "fe80::642:11";
    }
    {
      name = "wg-lax0-hkg0";
      port = 42431;
      a = "dedirock";
      b = "wawo";
      a6 = "fd22:1056:95a4:ffff::12";
      b6 = "fd22:1056:95a4:ffff::13";
      aLinkLocal = "fe80::642:12";
      bLinkLocal = "fe80::642:13";
    }
    {
      name = "wg-tyo0-hkg0";
      port = 42432;
      a = "geelinx-jp";
      b = "wawo";
      a6 = "fd22:1056:95a4:ffff::14";
      b6 = "fd22:1056:95a4:ffff::15";
      aLinkLocal = "fe80::642:14";
      bLinkLocal = "fe80::642:15";
    }
  ];

  enabled = builtins.hasAttr hostName nodes;
  localLinks = lib.filter (link: link.a == hostName || link.b == hostName) links;
  lookingGlassProxyPort = 8000;

  assertions =
    let
      nodeList = builtins.attrValues nodes;
      nodeIPv4s = map (node: node.ipv4) nodeList;
      nodeIPv6s = map (node: node.ipv6) nodeList;
      linkNames = map (link: link.name) links;
      ports = map (link: link.port) links;
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
    if link.a == hostName then
      {
        local6 = link.a6;
        localLinkLocal = link.aLinkLocal;
        peer = nodes.${link.b};
      }
    else
      {
        local6 = link.b6;
        localLinkLocal = link.bLinkLocal;
        peer = nodes.${link.a};
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
      node = nodes.${hostName};
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

      my.services.dn42.rejectASNs = [ ];
      my.services.dn42.flapDamping = {
        enable = true;
        runServer = lib.mkDefault false;
        serverAddress = nodes.geelinx-jp.ipv6;
      };

      networking.firewall = {
        allowedUDPPorts = map (link: link.port) localLinks;
        checkReversePath = false;
        interfaces = lib.listToAttrs (
          map (link: lib.nameValuePair link.name { allowedTCPPorts = [ lookingGlassProxyPort ]; }) localLinks
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

        babel = {
          enable = true;
          interfaces = lib.listToAttrs (
            map (link: lib.nameValuePair link.name { openFirewall = true; }) localLinks
          );
        };
      };

      services.bird = {
        enable = true;
        autoReload = true;
      };

      services.bird-lg.proxy = {
        enable = true;
        allowedIPs = [
          "127.0.0.1"
          nodes.dedirock.ipv4
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
