{
  my.hardware.ephemeralBtrfs = {
    device = "/dev/sda";
  };

  my.networking.static = {
    enable = true;
    macAddress = "00:16:3c:18:a8:bf";
    ipv4.prefixLength = 22;
    dns = [
      "1.0.0.1"
      "8.8.4.4"
    ];
  };

  my.services.sing-box = {
    enable = true;
    domain = "freehand-dubbed-ellipse-mulled.503418.xyz";
    port = 8443;
  };
}
