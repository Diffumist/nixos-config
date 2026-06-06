{
  config,
  inputs,
  hostName,
  lib,
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
    vmrack = {
      endpoint = "lax-0.diffumist.me";
      ipv4 = "172.22.64.67";
      ipv6 = "fd22:1056:95a4:3::1";
      publicKey = "GR4fsWfrkgNaYK+szxwbQfhCA2jI5BRu/BGOIAuzrF4=";
    };
    dedirock = {
      endpoint = "lax-1.diffumist.me";
      ipv4 = "172.22.64.68";
      ipv6 = "fd22:1056:95a4:4::1";
      publicKey = "viwkjXKilMxRupylyaqMHrZylzhW80+NypBNvVf/0G8=";
    };
    geelinx-jp = {
      endpoint = "tyo-0.diffumist.me";
      ipv4 = "172.22.64.69";
      ipv6 = "fd22:1056:95a4:5::1";
      publicKey = "KD/4v/fKXWXzvt2z3rxJN31QJIfw/cRSBq0nJppbYG4=";
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
      port = 42421;
      a = "liteserver";
      b = "vmrack";
      a6 = "fd22:1056:95a4:ffff::4";
      b6 = "fd22:1056:95a4:ffff::5";
      aLinkLocal = "fe80::642:4";
      bLinkLocal = "fe80::642:5";
    }
    {
      name = "wg-ams0-lax1";
      port = 42422;
      a = "liteserver";
      b = "dedirock";
      a6 = "fd22:1056:95a4:ffff::6";
      b6 = "fd22:1056:95a4:ffff::7";
      aLinkLocal = "fe80::642:6";
      bLinkLocal = "fe80::642:7";
    }
    {
      name = "wg-ams0-tyo0";
      port = 42423;
      a = "liteserver";
      b = "geelinx-jp";
      a6 = "fd22:1056:95a4:ffff::8";
      b6 = "fd22:1056:95a4:ffff::9";
      aLinkLocal = "fe80::642:8";
      bLinkLocal = "fe80::642:9";
    }
    {
      name = "wg-sjc0-lax0";
      port = 42424;
      a = "hostdzire";
      b = "vmrack";
      a6 = "fd22:1056:95a4:ffff::a";
      b6 = "fd22:1056:95a4:ffff::b";
      aLinkLocal = "fe80::642:a";
      bLinkLocal = "fe80::642:b";
    }
    {
      name = "wg-sjc0-lax1";
      port = 42425;
      a = "hostdzire";
      b = "dedirock";
      a6 = "fd22:1056:95a4:ffff::c";
      b6 = "fd22:1056:95a4:ffff::d";
      aLinkLocal = "fe80::642:c";
      bLinkLocal = "fe80::642:d";
    }
    {
      name = "wg-sjc0-tyo0";
      port = 42426;
      a = "hostdzire";
      b = "geelinx-jp";
      a6 = "fd22:1056:95a4:ffff::e";
      b6 = "fd22:1056:95a4:ffff::f";
      aLinkLocal = "fe80::642:e";
      bLinkLocal = "fe80::642:f";
    }
    {
      name = "wg-lax0-lax1";
      port = 42427;
      a = "vmrack";
      b = "dedirock";
      a6 = "fd22:1056:95a4:ffff::10";
      b6 = "fd22:1056:95a4:ffff::11";
      aLinkLocal = "fe80::642:10";
      bLinkLocal = "fe80::642:11";
    }
    {
      name = "wg-lax0-tyo0";
      port = 42428;
      a = "vmrack";
      b = "geelinx-jp";
      a6 = "fd22:1056:95a4:ffff::12";
      b6 = "fd22:1056:95a4:ffff::13";
      aLinkLocal = "fe80::642:12";
      bLinkLocal = "fe80::642:13";
    }
    {
      name = "wg-lax1-tyo0";
      port = 42429;
      a = "dedirock";
      b = "geelinx-jp";
      a6 = "fd22:1056:95a4:ffff::14";
      b6 = "fd22:1056:95a4:ffff::15";
      aLinkLocal = "fe80::642:14";
      bLinkLocal = "fe80::642:15";
    }
  ];

  enabled = builtins.hasAttr hostName nodes;
  localLinks = lib.filter (link: link.a == hostName || link.b == hostName) links;

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
        MTUBytes = "1420";
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
      sops.secrets.dn42_wg_private_key = {
        owner = "systemd-network";
        mode = "0400";
      };

      networking.firewall.allowedUDPPorts = map (link: link.port) localLinks;

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

      systemd.services.frr.enable = lib.mkForce false;

      systemd.network.netdevs = lib.listToAttrs (map mkNetdev localLinks);
      systemd.network.networks = lib.listToAttrs (map mkNetwork localLinks);

    }
  );
}
