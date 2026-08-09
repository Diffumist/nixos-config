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
      swapSize = "4096M";
    })

    ./services/attic.nix
    ./services/forgejo.nix
    ./services/garage-ui.nix
  ];

  my.networking.static = {
    enable = true;
    macAddress = "ea:be:e9:ad:7e:11";
    ipv4.prefixLength = 22;
    ipv6 = {
      enable = true;
      acceptRA = false;
      gatewayOnLink = true;
    };
  };

  my.services.postgresql = {
    totalRamMB = 8 * 1024;
    backup = {
      enable = true;
      accountId = "1ddb57c7f8266ea8489206984571fb77";
      bucket = "pgbackrest";
    };
  };

  my.services.garage = {
    enable = true;
    domain = "s3.418.cat";
    exposeS3 = true;
    bootstrapPeers = [
      "8e6345e4659cb1d16d804100cfb67cdfb4fefc318117d594cf4161718b0e2faf@ams-0.diffumist.me:3901"
    ];
  };
}
