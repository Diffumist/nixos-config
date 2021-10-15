{ pkgs, ... }:

{
  # HiDPI display
  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";
  services.xserver.dpi = 120;

  # Batery conservation mode
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 60; # Waiting tlp 1.4.0
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];

  # SSD trim
  services.fstrim = {
    enable = true;
    interval = "Sun";
  };

  services.timesyncd.enable = true;

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };
  virtualisation = {
    libvirtd = {
      enable = true;
      qemuPackage = pkgs.qemu_kvm;
    };
    podman.enable = true;
  };
  users.groups."libvirtd".members = [ "diffumist" ];

  programs.mtr.enable = true;

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
}
