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

  sops.defaultSopsFile = ./secrets.yaml;
  networking = {
    useDHCP = true;
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };

  services.resolved.enable = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.MACAddress = "00:16:3e:51:54:12";
    networkConfig = {
      DHCP = "ipv4";
    };
  };
  systemd.network.wait-online.enable = false;

  my.services.sing-box = {
    enable = true;
    firewallPorts = [ 8443 ];
    configSopsFile = ./services/sing-box.json;
  };
  my.services.postgresql.totalRamMB = 3 * 1024;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "solidvps";
}
