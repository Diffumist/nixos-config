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
    macAddress = "00:97:af:8f:84:a7";
    ipv4.prefixLength = 22;
    ipv6 = {
      enable = true;
      prefixLength = 56;
      acceptRA = false;
    };
  };
  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;
  my.services.sing-box = {
    enable = true;
    domain = "ambitious-enlisted-collected-pushcart.503418.xyz";
    port = 8443;
  };
  my.services.postgresql.totalRamMB = 1 * 1024;
}
