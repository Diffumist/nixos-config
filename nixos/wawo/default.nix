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
        Name=enp3s0

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

  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;

  environment.etc."vnstat.conf".text = ''
    MonthRotate 9
  '';

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "wowa";

  # AS213605 (Akaere Networks) hkg
  my.services.dn42-peers.akaere-hkg = {
    asn = 213605;
    listenPort = 23605;
    endpoint = "hk-dn42.akae.re";
    peerPort = 50642;
    publicKey = "tByhSmo8XuGZ5yplfdDYQRXUAjEzJzeY1Y4uF0xA0kk=";
    peerLinkLocal = "fe80::616b:6979";
  };

  # AS4242422189 (IEDON) hkg
  my.services.dn42-peers.iedon-hkg = {
    asn = 4242422189;
    listenPort = 22189;
    endpoint = "hk-hkg.dn42.iedon.net";
    peerPort = 33999;
    publicKey = "OlUDuWkUI9pKNsNo7Vjf/GKKVSBslh9kmqjbeYA4+34=";
    peerLinkLocal = "fe80::2189:120";
  };

  # AS4242423914 (Kioubit.dn42) hkg
  my.services.dn42-peers.kioubit-hkg = {
    asn = 4242423914;
    listenPort = 23914;
    endpoint = "hk1.g-load.eu";
    peerPort = 20057;
    publicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
    peerLinkLocal = "fe80::ade0";
  };

  # AS4242423088 (sunnet.dn42) hkg
  my.services.dn42-peers.sunnet-hkg = {
    asn = 4242423088;
    listenPort = 20;
    endpoint = "hk1.g-load.eu";
    peerPort = 20057;
    publicKey = "rBTH+JyZB0X/DkwHByrCjCojxBKr/kEOm1dTAFGHR1w=";
    peerLinkLocal = "fe80::ade0";
  };
}
