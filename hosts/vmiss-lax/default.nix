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
    macAddress = "d8:d5:d8:00:4c:91";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
      extraAddressSecrets = [
        "ipv6_address1"
        "ipv6_address2"
      ];
    };
  };
  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;
  my.services.sing-box = {
    enable = true;
    domain = "shun-pranker-pasture-molecular.503418.xyz";
    port = 8443;
  };
}
