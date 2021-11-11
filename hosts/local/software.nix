{ pkgs, ... }:

{
  # HiDPI display
  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";

  environment.sessionVariables = {
    WINIT_X11_SCALE_FACTOR = "1.5"; # Ref: https://github.com/alacritty/alacritty/issues/3792
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
    virtualbox.host.enable = true;
    # waydroid.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };
  users.groups."libvirtd".members = [ "diffumist" ];

  programs.mtr.enable = true;

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
}
