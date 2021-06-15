{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  services.xserver.dpi = 144;

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

  # services.printing.enable = true; # CUPS

  # services.transmission = {
  #   enable = true;
  #   home = "/home/transmission";
  # };
  # users.groups."transmission".members = [ "oxa" ];

  # services.fprintd.enable = true;
  # services.fprintd.package = pkgs.fprintd-thinkpad;

  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];
  # programs.wireshark.enable = true;
  # programs.wireshark.package = pkgs.wireshark;
  # users.groups."wireshark".members = [ "oxa" ];

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
