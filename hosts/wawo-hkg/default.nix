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
      swapSize = "512M";
    })
  ];

  my.networking.static = {
    enable = true;
    macAddress = "00:27:cb:6d:b0:97";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
    };
  };

  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };
  system.disableInstallerTools = true;
  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;

  my.services.sing-box = {
    enable = true;
    domain = "earache-pretty-anyway-squealing.503418.xyz";
  };
}
