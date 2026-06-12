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
  };
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  systemd.network.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    address = [
      "192.168.202.121/24"
      "2602:f9f3:1:7a::8964/64"
    ];
    routes = [
      {
        Gateway = "192.168.202.1";
      }
      {
        Gateway = "2602:f9f3:1::2";
        GatewayOnLink = true;
      }
    ];
  };

  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;

  # my.services.sing-box = {
  #   enable = true;
  #   firewallPorts = [ 8443 ];
  #   configSopsFile = ./services/sing-box.json;
  # };
  #
  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "texas";
}
