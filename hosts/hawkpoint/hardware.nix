{ pkgs, ... }:
{
  hardware = {
    bluetooth.enable = true;
    amdgpu.initrd.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    gvfs.enable = true;
    upower.enable = true;
    fstrim = {
      enable = true;
      interval = "Sun";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    pipewire.wireplumber.extraConfig."10-bluez" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [
          "hsp_hs"
          "hsp_ag"
          "hfp_hf"
          "hfp_ag"
        ];
      };
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
