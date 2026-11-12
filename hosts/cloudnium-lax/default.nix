{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./services/gatus.nix
    ./services/komari-monitor.nix
  ];

  # The system resolver caches negative DNS-01 answers beyond the ACME timeout.
  security.acme.defaults.dnsResolver = "1.1.1.1:53";

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

  # sudo -u postgres pgbackrest --stanza=default stanza-create
  # systemctl start pgbackrest-default-full.service
  # sudo -u postgres pgbackrest --stanza=default info
  my.services.postgresql = {
    totalRamMB = 2 * 1024;
    backup = {
      enable = true;
      accountId = "1ddb57c7f8266ea8489206984571fb77";
      bucket = "pgbackrest";
    };
  };
}
