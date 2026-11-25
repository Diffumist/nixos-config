{
  my.hardware.ephemeralBtrfs = {
    device = "/dev/sda";
  };

  my.networking.static = {
    enable = true;
    macAddress = "bc:24:11:47:05:95";
    ipv4.prefixLength = 24;
    dns = [
      "1.0.0.1"
      "8.8.4.4"
    ];
  };

  my.services.sing-box = {
    enable = true;
    domain = "overfed-thyself-colonize-distress.503418.xyz";
  };
}
