{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  imports = [
    (import ../../profiles/hardware/ephemeral-btrfs.nix {
      device = "/dev/vda";
    })
  ];

  my.networking.static = {
    enable = true;
    macAddress = "b2:ef:7d:00:04:27";
    ipv4.prefixLength = 24;
    dns = [
      "1.0.0.1"
      "8.8.4.4"
    ];
  };

  my.services.postgresql.totalRamMB = 2 * 1024;
}
