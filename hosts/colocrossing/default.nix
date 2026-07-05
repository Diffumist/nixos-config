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
    matchConfig.MACAddress = "00:16:3e:6b:25:cc";
    networkConfig = {
      DHCP = "ipv4";
    };
  };
}
