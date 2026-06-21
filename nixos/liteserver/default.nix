{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./boot.nix

    ./services/immich.nix
    ./services/rqbit.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      ipv4_address = { };
      ipv4_gateway = { };
      ipv6_address = { };
      ipv6_gateway = { };
    };
    templates."10-lan.network" = {
      path = "/etc/systemd/network/10-lan.network";
      owner = "systemd-network";
      content = ''
        [Match]
        Name=ens3

        [Network]
        Address=${config.sops.placeholder.ipv4_address}/24
        Address=${config.sops.placeholder.ipv6_address}/64
        Gateway=${config.sops.placeholder.ipv4_gateway}
        Gateway=${config.sops.placeholder.ipv6_gateway}
        DNS=1.0.0.1
        DNS=8.8.4.4
        DNS=2606:4700:4700::1001
        DNS=2001:4860:4860::8844
      '';
    };
  };
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  my.services.sing-box = {
    enable = true;
    firewallPorts = [ 8443 ];
    configSopsFile = ./services/sing-box.json;
  };
  my.services.postgresql.totalRamMB = 2 * 1024;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "liteserver";

  # AS4242423377 (leziblog) DE1 (NUE)
  my.services.dn42.peers.lezi-de = {
    asn = 4242423377;
    listenPort = 23377;
    endpoint = "v6.de1.peer.dn42.leziblog.com";
    peerPort = 20642;
    publicKey = "Kd5+CvZW3NRvUXpbdqGFt85VzMyReBtnVeDVXae06Qg=";
    peerLinkLocal = "fe80::3377";
    mtu = 1370;
  };

  # AS4242420253 (moe233) ams (Amsterdam)
  my.services.dn42.peers.moe233-ams = {
    asn = 4242420253;
    listenPort = 20253;
    endpoint = "ams.dn42.moe233.net";
    peerPort = 20642;
    publicKey = "vRRfNnGL7jpKGBJjLZg612vHQulDOtICkgXCC++1+2g=";
    peerLinkLocal = "fe80::253";
  };

  # AS4242422466 (SessNetwork) Netzilla (Frankfurt)
  my.services.dn42.peers.sess-de = {
    asn = 4242422466;
    listenPort = 22466;
    endpoint = "netzilla.xhustudio.eu.org";
    peerPort = 20642;
    publicKey = "NneXyO6ANmBoREGcDQh/KCi2MtkAGU4xS/HIkNB8wQg=";
    peerLinkLocal = "fe80::2466";
  };

  # AS4242423374 (baka.pub) nl01
  my.services.dn42.peers.baka-nl01 = {
    asn = 4242423374;
    listenPort = 23374;
    endpoint = "nl01.dn42.baka.pub";
    peerPort = 20642;
    publicKey = "xFZ0S57R5ykjq5lThYEvLLWHhv2+De5D26p4bX5wdSo=";
    peerLinkLocal = "fe80::2999:232";
  };

  # AS4242420298 (HExpNetwork) ams
  my.services.dn42.peers.hexp-ams = {
    asn = 4242420298;
    listenPort = 20298;
    endpoint = "ams.dn42.hexpnet.work";
    peerPort = 20642;
    publicKey = "ORoz9sxUr1TRfF9nx0Mqz1SPUARWZcD+upBvAm8pjw0=";
    peerLinkLocal = "fe80::298";
  };

  # AS4242423914 (Kioubit.dn42) DE
  my.services.dn42.peers.kioubit-de = {
    asn = 4242423914;
    listenPort = 23914;
    endpoint = "de2.g-load.eu";
    peerPort = 20077;
    publicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
    peerLinkLocal = "fe80::ade0";
  };

  # AS4242422189 (IEDON) ams
  my.services.dn42.peers.iedon-ams = {
    asn = 4242422189;
    listenPort = 22189;
    endpoint = "nl-ams.dn42.iedon.net";
    peerPort = 34302;
    publicKey = "08dzv758I5APqJizgw/W6O+FceyHSCbx/L/GZ3TL5TQ=";
    peerLinkLocal = "fe80::2189:177";
  };

  # AS4242423999 (CowGL) brn (Bern) - closest published node for AMS
  my.services.dn42.peers.cowgl-brn = {
    asn = 4242423999;
    listenPort = 23999;
    endpoint = "brn.node.cowgl.tech";
    peerPort = 30642;
    publicKey = "sHPUV74X+hqUK5wFj3m5kCga0rlPCxImUBwZ/oLiEn4=";
    peerLinkLocal = "fe80::3:3999";
  };

  # AS4242420925 (LU-LUX) - behind NAT, passive WireGuard endpoint
  my.services.dn42.peers.lu-lux = {
    asn = 4242420925;
    listenPort = 20925;
    publicKey = "JmjoF9DosETYg6++oO82eC3VvysK08ym7DTc/Z2RjB8=";
    peerLinkLocal = "fe80::925";
  };

  # AS213605 (Akaere Networks) ams
  my.services.dn42.peers.akaere-ams = {
    asn = 213605;
    listenPort = 23605;
    endpoint = "ams-dn42.akae.re";
    peerPort = 50642;
    publicKey = "noJ/5iddGjySp3hNI6yR+7QESJsUEzn6uspfk8Gs0io=";
    peerLinkLocal = "fe80::616b:6979";
  };
}
