{ lib, config, pkgs, ... }:
with lib;
let cfg = config.dmist.gnome-env; in
{
  options = {
    dmist.gnome-env = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      perlPackages.FileMimeInfo
      evince
      foliate
      lollypop
      gnome.eog
      gparted
      waydroid
      capitaine-cursors
      materia-theme
      materia-kde-theme
      papirus-icon-theme
      gnome.ghex
      gnome.gnome-tweaks
      gnome.dconf-editor
      gnome.gnome-screenshot
      gnome.nautilus
      gnome.gnome-system-monitor
      gnome.gnome-power-manager
      gnomeExtensions.lunar-calendar
      gnomeExtensions.kimpanel
      gnomeExtensions.gsconnect
      gnomeExtensions.appindicator
      gnomeExtensions.clipboard-indicator
    ];
    programs.dconf.enable = true;
    services.xserver = {
      enable = true;
      layout = "us";
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
        nvidiaWayland = true;
      };
      videoDrivers = [ "nvidia" ];
    };
    services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];
    services.gnome = {
      core-utilities.enable = false;
      core-developer-tools.enable = false;
      evolution-data-server.enable = true;
      gnome-online-accounts.enable = true;
      gnome-keyring.enable = true;
    };

    fonts = {
      fonts = with pkgs; [
        jetbrains-mono
        sarasa-gothic
        apple-emoji
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];
      fontDir.enable = true;
      fontconfig.defaultFonts = {
        monospace = [ "Jetbrains Mono" ];
        sansSerif = [ "Sarasa Gothic SC" ];
        serif = [ "Sarasa Gothic SC" ];
        emoji = [ "Apple Color Emoji" ];
      };
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8" ];
      inputMethod = {
        enabled = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-chinese-addons
          fcitx5-pinyin-zhwiki
          fcitx5-material-color
          fcitx5-pinyin-moegirl
        ];
      };
    };
    networking.networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        macAddress = "preserve";
      };
    };
  };
}
