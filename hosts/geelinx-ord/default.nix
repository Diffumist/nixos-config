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
      swapSize = "6144M";
    })
    # ./services/dst-server.nix
    ./services/matrix.nix
    ./services/misskey.nix
    ./services/notifications.nix
  ];

  my.networking.static = {
    enable = true;
    macAddress = "b2:ef:7d:00:04:86";
    ipv4.prefixLength = 26;
    ipv6 = {
      enable = true;
      acceptRA = false;
    };
  };

  my.services.postgresql = {
    enable = true;
    totalRamMB = 2 * 1024;
  };
}
