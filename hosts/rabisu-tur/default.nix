{
  my.hardware.ephemeralBtrfs.device = "/dev/vda";

  my.networking.static = {
    enable = true;
    macAddress = "ce:b4:3b:2b:18:7e";
    ipv4.prefixLength = 24;
    dns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  my.services.komari-agent.enable = false;
  my.services.sing-box = {
    enable = true;
    domain = "watch-revoke-undermine-caravan.503418.xyz";
  };
}
