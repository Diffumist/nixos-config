{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  my.hardware.ephemeralBtrfs = {
    device = "/dev/vda";
  };

  my.networking.static = {
    enable = true;
    macAddress = "18:7b:d5:43:49:d4";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
    };
  };

  my.services.postgresql.totalRamMB = 2 * 1024;
}
