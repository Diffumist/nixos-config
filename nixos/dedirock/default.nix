{
  pkgs,
  config,
  lib,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./boot.nix

    ./services/sillytavern.nix
    ./services/rustypaste.nix
    ./services/looking-glass.nix
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

  # AS4242423377 (leziblog) US1 (LAX)
  my.services.dn42-peers.lezi-lax = {
    asn = 4242423377;
    listenPort = 23377;
    endpoint = "v6.los1-us.peer.dn42.leziblog.com";
    peerPort = 20642;
    publicKey = "Xzt9UrH2moj84QSH0jsw8Zj+jwXwdBLpApe4hHyfnAw=";
    peerLinkLocal = "fe80::3377";
    mtu = 1420;
  };

  # AS4242420253 (moe233) lv (Las Vegas)
  my.services.dn42-peers.moe233-lv = {
    asn = 4242420253;
    listenPort = 20253;
    endpoint = "lv.dn42.moe233.net";
    peerPort = 20642;
    publicKey = "C3SneO68SmagisYQ3wi5tYI2R9g5xedKkB56Y7rtPUo=";
    peerLinkLocal = "fe80::253";
  };

  # AS4242423999 (CowGL) lax
  my.services.dn42-peers.cowgl-lax = {
    asn = 4242423999;
    listenPort = 23999;
    endpoint = "lax.node.cowgl.tech";
    peerPort = 30642;
    publicKey = "jhOukGNAKHI8Ivn8uI1TS25n5ho/rVlKFfenGmwCVlg=";
    peerLinkLocal = "fe80::2:3999";
  };

  # AS4242423310 (peer42.tmpfs.dev) US1 (LAX)
  my.services.dn42-peers.tmpfs-lax = {
    asn = 4242423310;
    listenPort = 23310;
    endpoint = "lax01.edge.r1.tmpfs.dev";
    peerPort = 20642;
    publicKey = "qEffOA35Oe2IFUFXv7KTGGZ5SV3XmrM+IxTdzHEDmCg=";
    peerLinkLocal = "fe80::0642:3310";
  };

  # AS4242423914 (Kioubit.dn42) US3 (LAX)
  my.services.dn42-peers.kioubit-lax = {
    asn = 4242423914;
    listenPort = 23914;
    endpoint = "us3.g-load.eu";
    peerPort = 20034;
    publicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
    peerLinkLocal = "fe80::ade0";
  };

  # AS4242421816 (Potat0) lv (Las Vegas)
  my.services.dn42-peers.potat0-lax = {
    asn = 4242421816;
    listenPort = 21816;
    endpoint = "las.node.potat0.cc";
    peerPort = 20642;
    publicKey = "LUwqKS6QrCPv510Pwt1eAIiHACYDsbMjrkrbGTJfviU=";
    peerLinkLocal = "fe80::1816";
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "dedirock";

  # Yukisino IX VM mesh (WG only, no BGP — Alpine doesn't run our stack)
  systemd.network.netdevs."20-wg-ix" = {
    netdevConfig = {
      Name = "wg-ix";
      Kind = "wireguard";
      MTUBytes = "8920";
    };
    wireguardConfig = {
      ListenPort = 42430;
      PrivateKeyFile = config.sops.secrets.dn42_wg_private_key.path;
    };
    wireguardPeers = [{
      PublicKey = "xa5t/tHR840xN+lGTt53jcbmvwU8RU8qC0m+iz2D20c=";
      Endpoint = "[2a14:ae00:55:2466:1266:6aff:fe4a:9efc]:42430";
      AllowedIPs = [ "0.0.0.0/0" "::/0" ];
      PersistentKeepalive = 25;
    }];
  };
  systemd.network.networks."20-wg-ix" = {
    matchConfig.Name = "wg-ix";
    address = [ "10.99.0.2/30" "fd22:dead:1::2/127" ];
    routes = [{ Destination = "242.99.55.190/32"; }];
    linkConfig.RequiredForOnline = "no";
  };
  networking.firewall.interfaces.wg-ix.allowedTCPPorts = [ 179 ];

  services.bird.config = lib.mkAfter ''
    protocol static {
      ipv4;
      route 242.99.55.190/32 via 10.99.0.1;
    }
  '';
}
