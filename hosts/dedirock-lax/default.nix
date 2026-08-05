{
  pkgs,
  config,
  lib,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./boot.nix

    ./services/sillytavern.nix
    ./services/rustypaste.nix
    ./services/looking-glass.nix
  ];

  my.networking.static = {
    enable = true;
    macAddress = "00:16:3e:d0:12:64";
    ipv4.prefixLength = 25;
    ipv6 = {
      enable = true;
    };
  };

  my.services.sing-box = {
    enable = true;
    domain = "pastel-riot-defense-stinking-saga.503418.xyz";
    port = 8443;
  };
  my.services.postgresql.totalRamMB = 2 * 1024;

}
