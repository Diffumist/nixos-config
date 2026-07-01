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
    matchConfig.MACAddress = "42:01:0a:8a:00:03";
    networkConfig = {
      DHCP = "ipv4";
    };
  };
  systemd.network.wait-online.enable = false;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "oregon";
}
