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
        Name=ens17

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

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "geelinx-jp";
}
