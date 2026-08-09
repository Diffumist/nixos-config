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
  ];

  my.networking.static = {
    enable = true;
    macAddress = "26:f3:70:00:03:7d";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
      extraAddressSecrets = [
        "ipv6_address1"
        "ipv6_address2"
        "ipv6_address3"
        "ipv6_address4"
      ];
    };
  };
}
