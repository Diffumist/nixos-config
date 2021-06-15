{ lib, config, pkgs, ... }:
with lib;
{
  environment.systemPackages = with pkgs; [
    (ark.override { unfreeEnableUnrar = true; })
    filelight
    kdeconnect scrcpy
    plasma-browser-integration
    spectacle
    latte-dock
    plasma-systemmonitor
    materia-theme
    papirus-icon-theme
    v2ray
    v2ray-geoip
    v2ray-domain-list-community
    (qv2ray.override { plugins = [ qv2ray-plugin-ss ]; })
  ];

  programs.partition-manager.enable = true;

  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  services.xserver = {
    enable = true;
    layout = "us";

    desktopManager.plasma5.enable = true;
    displayManager.sddm.enable = true;
  };

  security.pam.services.sddm.enableKwallet = true;

  fonts = {
    fonts = with pkgs; [ 
      jetbrains-mono
      noto-fonts-cjk
      emojione
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];
    fontDir.enable = true;
    fontconfig.defaultFonts = {
      monospace = [ "Jetbrains Mono" ];
      sansSerif = [ "Noto Sans CJK SC" ];
      serif = [ "Noto Sans CJK SC" ];
      emoji = [ "EmojiOne Color" ];
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
    };
  };

  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "preserve";
  };

  environment.etc = {
    "xdg/kdeglobals".source = ./xdg/kdeglobals;
    "xdg/kglobalshortcutsrc".source = ./xdg/kglobalshortcutsrc;
    "xdg/kwinrc".source = ./xdg/kwinrc;
    "xdg/kwinrulesrc".source = ./xdg/kwinrulesrc;
    "xdg/spectaclerc".source = ./xdg/spectaclerc;
    "xdg/startkderc".source = ./xdg/startkderc;
  };
}
