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

    ./services/gonic.nix
    ./services/http418-cat.nix
    ./services/immich.nix
    ./services/transmission.nix
  ];

  my.networking.static = {
    enable = true;
    macAddress = "00:16:3e:0a:f5:c6";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
    };
  };

  my.services.sing-box = {
    enable = true;
    domain = "reactive-grievous-deface-staining.503418.xyz";
    port = 8443;
  };

  my.services.postgresql = {
    totalRamMB = 2 * 1024;
    backup = {
      enable = true;
      accountId = "1ddb57c7f8266ea8489206984571fb77";
      bucket = "pgbackrest";
    };
  };

  my.services.garage = {
    enable = true;
    bootstrapPeers = [
      "fe629fe8562a739872199942834603ae5f4ddd90799ee2cd17f033b5eedb9d24@git.418.cat:3901"
    ];
  };
}
