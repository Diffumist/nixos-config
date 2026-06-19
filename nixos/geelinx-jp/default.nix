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
    ./services/notifications.nix
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
        Name=ens17 enp0s17

        [Network]
        Address=${config.sops.placeholder.ipv4_address}/25
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
  networking.hostName = "geelinx-jp";

  # AS4242423377 (leziblog) JP1 (TYO)
  my.services.dn42-peers.lezi-tyo = {
    asn = 4242423377;
    listenPort = 23377;
    endpoint = "v6.jp1-tyo.peer.dn42.leziblog.com";
    peerPort = 20642;
    publicKey = "U5nwXXxCQIWOVBzgdxCA7oPG4R6n7cF+igsZH8q84HY=";
    peerLinkLocal = "fe80::3377";
    mtu = 1420;
  };

  # AS4242420253 (moe233) tyo (Tokyo)
  my.services.dn42-peers.moe233-tyo = {
    asn = 4242420253;
    listenPort = 20253;
    endpoint = "tyo.dn42.moe233.net";
    peerPort = 20642;
    publicKey = "ONXSHr75I/5hjBOaYZicoxhV9tcBR+y83VXibXbO83M=";
    peerLinkLocal = "fe80::253";
  };

  # AS4242423999 (CowGL) tyo (Tokyo)
  my.services.dn42-peers.cowgl-tyo = {
    asn = 4242423999;
    listenPort = 23999;
    endpoint = "tyo.node.cowgl.tech";
    peerPort = 30642;
    publicKey = "mMGGxtEqsagrx1Raw57C2H3Stl6ch/cUuF7y08eVgBE=";
    peerLinkLocal = "fe80::1:3999";
  };

  # AS4242423374 (baka.pub) jp01
  my.services.dn42-peers.baka-jp01 = {
    asn = 4242423374;
    listenPort = 23374;
    endpoint = "jp01.dn42.baka.pub";
    peerPort = 20642;
    publicKey = "N7iQzqWLPb6lpRlf7grQG6rEzQOvDZWkmsRDkRnniH0=";
    peerLinkLocal = "fe80::2999:226";
  };

  # AS4242420298 (HExpNetwork) tyo
  my.services.dn42-peers.hexp-tyo = {
    asn = 4242420298;
    listenPort = 20298;
    endpoint = "tyo.dn42.hexpnet.work";
    peerPort = 20642;
    publicKey = "2gXTILCzuWks2JfCu+k/429blyBcOGVteXJuI6odqBA=";
    peerLinkLocal = "fe80::298";
  };

  # AS4242421857 (luocynet) tyo
  my.services.dn42-peers.luocynet-tyo = {
    asn = 4242421857;
    listenPort = 21857;
    endpoint = "jp1.dn42.luocynet.com";
    peerPort = 20642;
    publicKey = "4mrkVld0RCE5Tkn0v0xkiyMiT+cDQSRfL6AoMb3rzQg=";
    peerLinkLocal = "fe80::1857:239";
  };

  # AS4242421023 (owo.li) tyo
  my.services.dn42-peers.owo-tyo = {
    asn = 4242421023;
    listenPort = 21023;
    endpoint = "tyo-01.node.svc.moe";
    peerPort = 20642;
    publicKey = "pv0bwaUm/ppI7Yaoi7w0qrXX5EW7Qo2njTSNG19AHgM=";
    peerLinkLocal = "fe80::1023:2";
  };

  # AS4242422189 (IEDON) tyo
  my.services.dn42-peers.iedon-tyo = {
    asn = 4242422189;
    listenPort = 22189;
    endpoint = "jp-ty2.dn42.iedon.net";
    peerPort = 55792;
    publicKey = "XjKsLfOYJ8y/U9saLpfM/MjXErlQ7gkw3+OgQTdVZ0U=";
    peerLinkLocal = "fe80::2189:115";
  };
}
