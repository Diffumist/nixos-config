{ inputs, ... }:
let
  baseurl = "diffumist.me";
in
{
  my.services.dn42.mesh = {
    enable = true;
    asn = 4242420642;
    ipv4Pool = "172.22.64.64/27";
    ipv6Pool = "fd22:1056:95a4::/48";
    roaRegistry = inputs.dn42-registry;
    lookingGlassAllowedNode = "lax0";

    flapDamping.serverAddress = "fd22:1056:95a4:4::1179";

    nodes = {
      ams0 = {
        hostName = "liteserver-ams";
        endpoint = "ams-0.${baseurl}";
        ipv4 = "172.22.64.65";
        ipv6 = "fd22:1056:95a4:1::1";
        publicKey = "25KV0x3WcKCCg7HcTVAB+27LrMpIfrZl05hgX5QGnzU=";
      };
      sjc0 = {
        hostName = "hostdzire-sfo";
        endpoint = "sjc-0.${baseurl}";
        ipv4 = "172.22.64.66";
        ipv6 = "fd22:1056:95a4:2::1";
        publicKey = "byljo5bFvup+YtQbae/m3ReiWFwCHFN+CAWinzirvQo=";
      };
      lax0 = {
        hostName = "dedirock-lax";
        endpoint = "lax-0.${baseurl}";
        ipv4 = "172.22.64.67";
        ipv6 = "fd22:1056:95a4:3::1";
        publicKey = "viwkjXKilMxRupylyaqMHrZylzhW80+NypBNvVf/0G8=";
      };
      tyo0 = {
        hostName = "noboard-tyo";
        endpoint = "tyo-0.${baseurl}";
        ipv4 = "172.22.64.68";
        ipv6 = "fd22:1056:95a4:4::1";
        publicKey = "KD/4v/fKXWXzvt2z3rxJN31QJIfw/cRSBq0nJppbYG4=";
      };
      hkg0 = {
        hostName = "wawo-hkg";
        endpoint = "hkg-0.${baseurl}";
        ipv4 = "172.22.64.69";
        ipv6 = "fd22:1056:95a4:5::1";
        publicKey = "3anHMuAw/sDlRCN7xoRUf1l4SdAu0Rfl2pqpeJtJn3Y=";
      };
      nue0 = {
        hostName = "netcup-nue";
        endpoint = "nue-0.${baseurl}";
        ipv4 = "172.22.64.70";
        ipv6 = "fd22:1056:95a4:6::1";
        publicKey = "Ti77y04KRfP/GRLPp87cw/8tcIB4Z6+phjOTQhoqHBQ=";
      };
    };

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
        port = 42421;
        a4 = "192.168.242.4";
        b4 = "192.168.242.5";
        a6 = "fd22:1056:95a4:ffff::4";
        b6 = "fd22:1056:95a4:ffff::5";
        aLinkLocal = "fe80::642:4";
        bLinkLocal = "fe80::642:5";
      }
      {
        name = "wg-sjc0-lax0";
        port = 42422;
        a4 = "192.168.242.8";
        b4 = "192.168.242.9";
        a6 = "fd22:1056:95a4:ffff::8";
        b6 = "fd22:1056:95a4:ffff::9";
        aLinkLocal = "fe80::642:8";
        bLinkLocal = "fe80::642:9";
      }
      {
        name = "wg-sjc0-tyo0";
        port = 42423;
        a4 = "192.168.242.10";
        b4 = "192.168.242.11";
        a6 = "fd22:1056:95a4:ffff::10";
        b6 = "fd22:1056:95a4:ffff::11";
        aLinkLocal = "fe80::642:10";
        bLinkLocal = "fe80::642:11";
      }
      {
        name = "wg-lax0-tyo0";
        port = 42424;
        a4 = "192.168.242.12";
        b4 = "192.168.242.13";
        a6 = "fd22:1056:95a4:ffff::12";
        b6 = "fd22:1056:95a4:ffff::13";
        aLinkLocal = "fe80::642:12";
        bLinkLocal = "fe80::642:13";
      }
      {
        name = "wg-ams0-hkg0";
        port = 42425;
        a4 = "192.168.242.14";
        b4 = "192.168.242.15";
        a6 = "fd22:1056:95a4:ffff::14";
        b6 = "fd22:1056:95a4:ffff::15";
        aLinkLocal = "fe80::642:14";
        bLinkLocal = "fe80::642:15";
      }
      {
        name = "wg-lax0-hkg0";
        port = 42426;
        a4 = "192.168.242.16";
        b4 = "192.168.242.17";
        a6 = "fd22:1056:95a4:ffff::16";
        b6 = "fd22:1056:95a4:ffff::17";
        aLinkLocal = "fe80::642:16";
        bLinkLocal = "fe80::642:17";
      }
      {
        name = "wg-tyo0-hkg0";
        port = 42427;
        a4 = "192.168.242.18";
        b4 = "192.168.242.19";
        a6 = "fd22:1056:95a4:ffff::18";
        b6 = "fd22:1056:95a4:ffff::19";
        aLinkLocal = "fe80::642:18";
        bLinkLocal = "fe80::642:19";
      }
      {
        name = "wg-ams0-nue0";
        port = 42428;
        a4 = "192.168.242.20";
        b4 = "192.168.242.21";
        a6 = "fd22:1056:95a4:ffff::20";
        b6 = "fd22:1056:95a4:ffff::21";
        aLinkLocal = "fe80::642:20";
        bLinkLocal = "fe80::642:21";
      }
    ];
  };
}
