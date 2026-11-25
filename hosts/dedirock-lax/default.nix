{
  imports = [
    ./services/sillytavern.nix
    ./services/rustypaste.nix
  ];

  my.hardware.ephemeralBtrfs = {
    device = "/dev/vda";
  };

  my.networking.static = {
    enable = true;
    macAddress = "00:16:3e:d0:12:64";
    ipv4.prefixLength = 25;
    ipv6 = {
      enable = true;
    };
  };

  my.services.mihomo-server = {
    enable = true;
    domain = "pastel-riot-defense-stinking-saga.503418.xyz";
    port = 8443;
  };
}
