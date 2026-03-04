{ pkgs, ... }:
{
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    priority = 50;
  };
  hardware = {
    bluetooth.enable = true;
    amdgpu.initrd.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    tuxedo-rs = {
      enable = true;
      tailor-gui.enable = true;
    };
  };

  services = {
    gvfs.enable = true;
    upower.enable = true;
    fstrim = {
      enable = true;
      interval = "Sun";
    };
  };
  # Wake
  services.udev.extraRules = ''
    # Disable wakeup for 2.4G mouse receiver
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2023", ATTR{idProduct}=="f013", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
  '';

  # yubikey
  services.udev.packages = [ pkgs.yubikey-personalization ];
  security.pam = {
    u2f = {
      enable = true;
      settings.cue = true;
    };
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
  };
}
