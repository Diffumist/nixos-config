{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./services/asterisk.nix
    ./services/grafana.nix
    ./services/pocketid.nix
    ./services/oauth2.nix
    ./services/powerdns.nix
    ./services/restic.nix
    ./services/vaultwarden.nix
  ];

  my.hardware.ephemeralBtrfs = {
    device = "/dev/sda";
    swapSize = "3G";
  };

  my.services.mihomo-server = {
    enable = true;
    domain = "generic-radiance-multitude-reversing.503418.xyz";
    port = 8443;
  };

  my.services.postgresql = {
    totalRamMB = 6 * 1024;
    backup = {
      enable = true;
      accountId = "1ddb57c7f8266ea8489206984571fb77";
      bucket = "pgbackrest";
    };
  };
}
