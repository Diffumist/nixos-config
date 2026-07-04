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
  networking = {
    useDHCP = true;
  };

  services.resolved.enable = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.MACAddress = "42:01:0a:80:00:02";
    networkConfig = {
      DHCP = "ipv4";
    };
  };
}
