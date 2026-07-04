{ hostName, ... }:
let
  peers = {
    liteserver = {
      # AS4242423377 (leziblog) DE1 (NUE)
      lezi-de = {
        asn = 4242423377;
        listenPort = 23377;
        endpoint = "v6.de1.peer.dn42.leziblog.com";
        peerPort = 20642;
        publicKey = "Kd5+CvZW3NRvUXpbdqGFt85VzMyReBtnVeDVXae06Qg=";
        peerLinkLocal = "fe80::3377";
        mtu = 1370;
      };

      # AS4242420253 (moe233) ams (Amsterdam)
      moe233-ams = {
        asn = 4242420253;
        listenPort = 20253;
        endpoint = "ams.dn42.moe233.net";
        peerPort = 20642;
        publicKey = "vRRfNnGL7jpKGBJjLZg612vHQulDOtICkgXCC++1+2g=";
        peerLinkLocal = "fe80::253";
      };

      # AS4242422466 (SessNetwork) Netzilla (Frankfurt)
      sess-de = {
        asn = 4242422466;
        listenPort = 22466;
        endpoint = "netzilla.xhustudio.eu.org";
        peerPort = 20642;
        publicKey = "NneXyO6ANmBoREGcDQh/KCi2MtkAGU4xS/HIkNB8wQg=";
        peerLinkLocal = "fe80::2466";
      };

      # AS4242423374 (baka.pub) nl01
      baka-nl01 = {
        asn = 4242423374;
        listenPort = 23374;
        endpoint = "nl01.dn42.baka.pub";
        peerPort = 20642;
        publicKey = "xFZ0S57R5ykjq5lThYEvLLWHhv2+De5D26p4bX5wdSo=";
        peerLinkLocal = "fe80::2999:232";
      };

      # AS4242420298 (HExpNetwork) ams
      hexp-ams = {
        asn = 4242420298;
        listenPort = 20298;
        endpoint = "ams.dn42.hexpnet.work";
        peerPort = 20642;
        publicKey = "ORoz9sxUr1TRfF9nx0Mqz1SPUARWZcD+upBvAm8pjw0=";
        peerLinkLocal = "fe80::298";
      };

      # AS4242423914 (Kioubit.dn42) DE
      kioubit-de = {
        asn = 4242423914;
        listenPort = 23914;
        endpoint = "de2.g-load.eu";
        peerPort = 20077;
        publicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
        peerLinkLocal = "fe80::ade0";
      };

      # AS4242422189 (IEDON) ams
      iedon-ams = {
        asn = 4242422189;
        listenPort = 22189;
        endpoint = "nl-ams.dn42.iedon.net";
        peerPort = 34302;
        publicKey = "08dzv758I5APqJizgw/W6O+FceyHSCbx/L/GZ3TL5TQ=";
        peerLinkLocal = "fe80::2189:177";
      };

      # AS4242423999 (CowGL) brn (Bern) - closest published node for AMS
      cowgl-brn = {
        asn = 4242423999;
        listenPort = 23999;
        endpoint = "brn.node.cowgl.tech";
        peerPort = 30642;
        publicKey = "sHPUV74X+hqUK5wFj3m5kCga0rlPCxImUBwZ/oLiEn4=";
        peerLinkLocal = "fe80::3:3999";
      };

      # AS4242420925 (LU-LUX) - behind NAT, passive WireGuard endpoint
      lu-lux = {
        asn = 4242420925;
        listenPort = 20925;
        publicKey = "JmjoF9DosETYg6++oO82eC3VvysK08ym7DTc/Z2RjB8=";
        peerLinkLocal = "fe80::925";
      };

      # AS213605 (Akaere Networks) ams
      akaere-ams = {
        asn = 213605;
        listenPort = 23605;
        endpoint = "ams-dn42.akae.re";
        peerPort = 50642;
        publicKey = "noJ/5iddGjySp3hNI6yR+7QESJsUEzn6uspfk8Gs0io=";
        peerLinkLocal = "fe80::616b:6979";
      };
    };

    hostdzire = {
      # AS4242422466 (SessNetwork) Chronnection (San Jose)
      sess-sjc = {
        asn = 4242422466;
        listenPort = 22466;
        endpoint = "chron-nection.xhustudio.eu.org";
        peerPort = 20642;
        publicKey = "tA6SZZYpCdr4zkkk2pCpuDDiyxcHIsksOhwWnzLIVw8=";
        peerLinkLocal = "fe80::2466";
      };

      # AS4242420454 (nedifinita) Chronnection (Seattle)
      nedi-sea = {
        asn = 4242420454;
        listenPort = 20454;
        endpoint = "dn42a.nedifinita.com";
        peerPort = 41324;
        publicKey = "8EXT6zciVdil3Zg6dqB0YT2SssTh2OTKDeBBfrVGUkE=";
        peerLinkLocal = "fe80::454";
      };

      # AS4242420298 (HExpNetwork) sjc
      hexp-sjc = {
        asn = 4242420298;
        listenPort = 20298;
        endpoint = "sjc.dn42.hexpnet.work";
        peerPort = 20642;
        publicKey = "fKuqaW7QYOfC9UXWrgjgqVicQUn6XglCemH7Efd/XlM=";
        peerLinkLocal = "fe80::298";
      };

      # AS4242423658 (xaven) sjc
      xaven-sjc = {
        asn = 4242423658;
        listenPort = 23658;
        endpoint = "107.148.41.99";
        peerPort = 20642;
        publicKey = "MWIKfVn84ekQvpR1wWLIy1pWL4nrwXDatvK5mLxilD8=";
        peerLinkLocal = "fe80::3658";
      };

      # AS4242422189 (IEDON) sjc
      iedon-sjc = {
        asn = 4242422189;
        listenPort = 22189;
        endpoint = "us-sjc.dn42.iedon.net";
        peerPort = 59878;
        publicKey = "Sz0UhewjDk2yRKI0QL9rB+5daWpXFVlbbz9cLfVVLn4=";
        peerLinkLocal = "fe80::2189:e8";
      };
    };

    dedirock = {
      # AS4242423377 (leziblog) US1 (LAX)
      lezi-lax = {
        asn = 4242423377;
        listenPort = 23377;
        endpoint = "v6.los1-us.peer.dn42.leziblog.com";
        peerPort = 20642;
        publicKey = "Xzt9UrH2moj84QSH0jsw8Zj+jwXwdBLpApe4hHyfnAw=";
        peerLinkLocal = "fe80::3377";
        mtu = 1420;
      };

      # AS4242420253 (moe233) lv (Las Vegas)
      moe233-lv = {
        asn = 4242420253;
        listenPort = 20253;
        endpoint = "lv.dn42.moe233.net";
        peerPort = 20642;
        publicKey = "C3SneO68SmagisYQ3wi5tYI2R9g5xedKkB56Y7rtPUo=";
        peerLinkLocal = "fe80::253";
      };

      # AS4242423999 (CowGL) lax
      cowgl-lax = {
        asn = 4242423999;
        listenPort = 23999;
        endpoint = "lax.node.cowgl.tech";
        peerPort = 30642;
        publicKey = "jhOukGNAKHI8Ivn8uI1TS25n5ho/rVlKFfenGmwCVlg=";
        peerLinkLocal = "fe80::2:3999";
      };

      # AS4242423310 (peer42.tmpfs.dev) US1 (LAX)
      tmpfs-lax = {
        asn = 4242423310;
        listenPort = 23310;
        endpoint = "lax01.edge.r1.tmpfs.dev";
        peerPort = 20642;
        publicKey = "qEffOA35Oe2IFUFXv7KTGGZ5SV3XmrM+IxTdzHEDmCg=";
        peerLinkLocal = "fe80::0642:3310";
      };

      # AS4242423914 (Kioubit.dn42) US3 (LAX)
      kioubit-lax = {
        asn = 4242423914;
        listenPort = 23914;
        endpoint = "us3.g-load.eu";
        peerPort = 20034;
        publicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
        peerLinkLocal = "fe80::ade0";
      };

      # AS4242421816 (Potat0) lv (Las Vegas)
      potat0-lax = {
        asn = 4242421816;
        listenPort = 21816;
        endpoint = "las.node.potat0.cc";
        peerPort = 20642;
        publicKey = "LUwqKS6QrCPv510Pwt1eAIiHACYDsbMjrkrbGTJfviU=";
        peerLinkLocal = "fe80::1816";
      };

      # AS4242421023 (owo.li) lax
      owo-lax = {
        asn = 4242421023;
        listenPort = 21023;
        endpoint = "lax-01.node.svc.moe";
        peerPort = 20642;
        publicKey = "nwMyp5pohAUDaaT2oVQQZiE/EI31DnnxVqAcKIWSuiM=";
        peerLinkLocal = "fe80::1023:2";
      };

      # AS4242422189 (IEDON) lax
      iedon-lax = {
        asn = 4242422189;
        listenPort = 22189;
        endpoint = "us-lax.dn42.iedon.net";
        peerPort = 40944;
        publicKey = "DIw4TKAQelurK10Sh1qE6IiDKTqL1yciI5ItwBgcHFA=";
        peerLinkLocal = "fe80::2189:ef";
      };
    };

    geelinx-jp = {
      # AS4242423377 (leziblog) JP1 (TYO)
      lezi-tyo = {
        asn = 4242423377;
        listenPort = 23377;
        endpoint = "v6.jp1-tyo.peer.dn42.leziblog.com";
        peerPort = 20642;
        publicKey = "U5nwXXxCQIWOVBzgdxCA7oPG4R6n7cF+igsZH8q84HY=";
        peerLinkLocal = "fe80::3377";
        mtu = 1420;
      };

      # AS4242420253 (moe233) tyo (Tokyo)
      moe233-tyo = {
        asn = 4242420253;
        listenPort = 20253;
        endpoint = "tyo.dn42.moe233.net";
        peerPort = 20642;
        publicKey = "ONXSHr75I/5hjBOaYZicoxhV9tcBR+y83VXibXbO83M=";
        peerLinkLocal = "fe80::253";
      };

      # AS4242423999 (CowGL) tyo (Tokyo)
      cowgl-tyo = {
        asn = 4242423999;
        listenPort = 23999;
        endpoint = "tyo.node.cowgl.tech";
        peerPort = 30642;
        publicKey = "mMGGxtEqsagrx1Raw57C2H3Stl6ch/cUuF7y08eVgBE=";
        peerLinkLocal = "fe80::1:3999";
      };

      # AS4242423374 (baka.pub) jp01
      baka-jp01 = {
        asn = 4242423374;
        listenPort = 23374;
        endpoint = "jp01.dn42.baka.pub";
        peerPort = 20642;
        publicKey = "N7iQzqWLPb6lpRlf7grQG6rEzQOvDZWkmsRDkRnniH0=";
        peerLinkLocal = "fe80::2999:226";
      };

      # AS4242420298 (HExpNetwork) tyo
      hexp-tyo = {
        asn = 4242420298;
        listenPort = 20298;
        endpoint = "tyo.dn42.hexpnet.work";
        peerPort = 20642;
        publicKey = "2gXTILCzuWks2JfCu+k/429blyBcOGVteXJuI6odqBA=";
        peerLinkLocal = "fe80::298";
      };

      # AS4242421857 (luocynet) tyo
      luocynet-tyo = {
        asn = 4242421857;
        listenPort = 21857;
        endpoint = "jp1.dn42.luocynet.com";
        peerPort = 20642;
        publicKey = "4mrkVld0RCE5Tkn0v0xkiyMiT+cDQSRfL6AoMb3rzQg=";
        peerLinkLocal = "fe80::1857:239";
      };

      # AS4242421023 (owo.li) tyo
      owo-tyo = {
        asn = 4242421023;
        listenPort = 21023;
        endpoint = "tyo-01.node.svc.moe";
        peerPort = 20642;
        publicKey = "pv0bwaUm/ppI7Yaoi7w0qrXX5EW7Qo2njTSNG19AHgM=";
        peerLinkLocal = "fe80::1023:2";
      };

      # AS4242422189 (IEDON) tyo
      iedon-tyo = {
        asn = 4242422189;
        listenPort = 22189;
        endpoint = "jp-ty2.dn42.iedon.net";
        peerPort = 55792;
        publicKey = "XjKsLfOYJ8y/U9saLpfM/MjXErlQ7gkw3+OgQTdVZ0U=";
        peerLinkLocal = "fe80::2189:115";
      };
    };

    wawo = {
      # AS213605 (Akaere Networks) hkg
      akaere-hkg = {
        asn = 213605;
        listenPort = 23605;
        endpoint = "hk-dn42.akae.re";
        peerPort = 50642;
        publicKey = "tByhSmo8XuGZ5yplfdDYQRXUAjEzJzeY1Y4uF0xA0kk=";
        peerLinkLocal = "fe80::616b:6979";
      };

      # AS4242422189 (IEDON) hkg
      iedon-hkg = {
        asn = 4242422189;
        listenPort = 22189;
        endpoint = "hk-hkg.dn42.iedon.net";
        peerPort = 33999;
        publicKey = "OlUDuWkUI9pKNsNo7Vjf/GKKVSBslh9kmqjbeYA4+34=";
        peerLinkLocal = "fe80::2189:120";
      };

      # AS4242423914 (Kioubit.dn42) hkg
      kioubit-hkg = {
        asn = 4242423914;
        listenPort = 23914;
        endpoint = "hk1.g-load.eu";
        peerPort = 20057;
        publicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
        peerLinkLocal = "fe80::ade0";
      };

      # AS4242423088 (sunnet.dn42) hkg
      sunnet-hkg = {
        asn = 4242423088;
        listenPort = 20;
        endpoint = "hk1.g-load.eu";
        peerPort = 20057;
        publicKey = "rBTH+JyZB0X/DkwHByrCjCojxBKr/kEOm1dTAFGHR1w=";
        peerLinkLocal = "fe80::ade0";
      };
    };
  };
in
{
  my.services.dn42.peers = peers.${hostName} or { };
}
