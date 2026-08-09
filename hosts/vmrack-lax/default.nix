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
    })
  ];

  my.networking.static = {
    enable = true;
    macAddress = "fa:16:3e:28:cb:41";
    ipv4.prefixLength = 24;
  };

  virtualisation.podman.enable = false;

  my.services.sing-box = {
    enable = true;
    domain = "nuttiness-bronzing-april-retorted-reclusive.503418.xyz";
  };
}
