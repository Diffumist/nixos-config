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
      device = "/dev/sda";
    })
  ];

  my.networking.static = {
    enable = true;
    macAddress = "00:16:3c:18:a8:bf";
    ipv4.prefixLength = 22;
    dns = [
      "1.0.0.1"
      "8.8.4.4"
    ];
  };
  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;
  my.services.sing-box = {
    enable = true;
    domain = "freehand-dubbed-ellipse-mulled.503418.xyz";
    port = 8443;
  };
  my.services.postgresql.totalRamMB = 1 * 1024;
}
