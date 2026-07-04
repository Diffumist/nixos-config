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
    matchConfig.MACAddress = "00:16:3e:51:54:12";
    networkConfig = {
      DHCP = "ipv4";
    };
  };
  my.services.sing-box = {
    enable = true;
    firewallPorts = [ 8443 ];
    configSopsFile = ./services/sing-box.json;
  };
  my.services.postgresql.totalRamMB = 3 * 1024;
}
