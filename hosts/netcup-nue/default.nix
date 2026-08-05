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
    macAddress = "b6:98:d8:83:c7:eb";
    ipv4.prefixLength = 22;
    ipv6 = {
      enable = true;
      acceptRA = false;
      gatewayOnLink = true;
    };
  };
  my.services.postgresql.totalRamMB = 1 * 1024;
}
