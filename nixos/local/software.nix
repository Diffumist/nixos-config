{ pkgs, ... }:

{
  # HiDPI display
  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";
  services.xserver.dpi = 120;

  environment.sessionVariables = {
    WINIT_X11_SCALE_FACTOR = "1.5"; # Ref: https://github.com/alacritty/alacritty/issues/3792
  };

  # Batery conservation mode
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 60;
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
      qemu.package = pkgs.qemu_kvm;
    };
    podman.enable = true;
  };
  users.groups."libvirtd".members = [ "diffumist" ];

  programs.mtr.enable = true;

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
}
