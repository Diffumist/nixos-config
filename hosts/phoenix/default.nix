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

    # ./services/cyber.nix
    ./services/attic.nix
  ];
  networking = {
    useDHCP = true;
  };

  services.resolved.enable = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.MACAddress = "00:16:3e:03:9a:2f";
    networkConfig = {
      DHCP = "ipv4";
    };
  };
  my.services.postgresql.totalRamMB = 16 * 1024;
}
