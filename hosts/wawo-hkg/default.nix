{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  my.hardware.ephemeralBtrfs = {
    device = "/dev/vda";
    swapSize = "512M";
  };

  my.networking.static = {
    enable = true;
    macAddress = "00:27:cb:6d:b0:97";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
    };
  };

  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;

  my.services.mihomo-server = {
    enable = true;
    domain = "earache-pretty-anyway-squealing.503418.xyz";
  };
}
