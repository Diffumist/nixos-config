{ pkgs, ... }:

{
  services.xserver.dpi = 120;

  networking.firewall = {
    logRefusedConnections = false;
  };

  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];

  # SSE Only
  services.fstrim = {
    enable = true;
    interval = "Wed";
  };

  services.timesyncd.enable = true;

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  programs.mtr.enable = true;

  environment.systemPackages = with pkgs; [
    cntr
    curl
    virt-manager
  ];
}
