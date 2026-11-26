{
  imports = [
    ./services/cpu-alerts.nix
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
    backup.enable = true;
  };
}
