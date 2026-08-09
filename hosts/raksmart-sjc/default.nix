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
      firmware = "uefi";
    })
  ];

  my.networking.static = {
    enable = true;
    macAddress = "52:54:06:5d:0e:6f";
    ipv4.prefixLength = 26;
    dns = [
      "1.0.0.1"
      "8.8.4.4"
    ];
  };
  virtualisation.podman.enable = true;
  services.fail2ban.enable = false;
  my.services.sing-box = {
    enable = true;
    domain = "bagging-decibel-unsightly-ought-snooper.503418.xyz";
  };
}
