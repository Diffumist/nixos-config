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

  # AS4242423377 (leziblog) DE1 (NUE)
  my.services.dn42-peers.lezi-de = {
    asn = 4242423377;
    listenPort = 23377;
    endpoint = "v6.de1.peer.dn42.leziblog.com";
    peerPort = 20642;
    publicKey = "Kd5+CvZW3NRvUXpbdqGFt85VzMyReBtnVeDVXae06Qg=";
    peerLinkLocal = "fe80::3377";
    mtu = 1370;
  };

  # AS4242420253 (moe233) ams (Amsterdam)
  my.services.dn42-peers.moe233-ams = {
    asn = 4242420253;
    listenPort = 20253;
    endpoint = "ams.dn42.moe233.net";
    peerPort = 20642;
    publicKey = "vRRfNnGL7jpKGBJjLZg612vHQulDOtICkgXCC++1+2g=";
    peerLinkLocal = "fe80::253";
  };

  # AS4242422466 (SessNetwork) Netzilla (Frankfurt) - IPv6-only endpoint
  my.services.dn42-peers.sess-de = {
    asn = 4242422466;
    listenPort = 22466;
    endpoint = "netzilla.xhustudio.eu.org";
    peerPort = 20642;
    publicKey = "NneXyO6ANmBoREGcDQh/KCi2MtkAGU4xS/HIkNB8wQg=";
    peerLinkLocal = "fe80::2466";
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "liteserver";
}
