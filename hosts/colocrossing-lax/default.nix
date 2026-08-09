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

    ./services/gatus.nix
    ./services/komari-monitor.nix
  ];
  networking = {
    useDHCP = true;
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

  services.resolved.enable = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.MACAddress = "00:16:3e:6b:25:cc";
    networkConfig = {
      DHCP = "ipv4";
    };
  };
}
