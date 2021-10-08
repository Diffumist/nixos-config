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
      START_CHARGE_THRESH_BAT0 = 75;
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
    kvmgt = {
      enable = true;
      # Random generated UUIDs.
      # vgpus."i915-GVTg_V5_4".uuid = "7a0eb5a3-9927-4613-a01e-24886e15c4a4"; # 1920x1200
      # vgpus."i915-GVTg_V5_8".uuid = [ "83d2cd0c-89aa-4045-8e8e-5796ac8d6d4f" ]; # 1024x768
    };
    podman.enable = true;
  };
  users.groups."libvirtd".members = [ "diffumist" ];

  programs.mtr.enable = true;

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
}
