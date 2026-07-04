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

  my.services.sing-box = {
    enable = true;
    firewallPorts = [ 8443 ];
    configSopsFile = ./services/sing-box.json;
  };
  my.services.postgresql.totalRamMB = 2 * 1024;
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
    wireguardPeers = [
      {
        PublicKey = "xa5t/tHR840xN+lGTt53jcbmvwU8RU8qC0m+iz2D20c=";
        Endpoint = "[2a14:ae00:55:2466:1266:6aff:fe4a:9efc]:42430";
        AllowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        PersistentKeepalive = 25;
      }
    ];
  };
  systemd.network.networks."20-wg-ix" = {
    matchConfig.Name = "wg-ix";
    address = [
      "10.99.0.2/30"
      "fd22:dead:1::2/127"
    ];
    routes = [ { Destination = "242.99.55.190/32"; } ];
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
