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
      meld
      srain
      kooha
      evince
      drawing
      remmina
      gparted
      lollypop
      newsflash
      wpsoffice
      gnome.eog
      gnome.ghex
      gnome.gedit
      gnome-builder
      gnome.nautilus
      gnome.file-roller
      gnome.gnome-tweaks
      gnome.dconf-editor
      gnome.gnome-screenshot
      gnome.gnome-power-manager
      gnome.gnome-system-monitor
      gnomeExtensions.gsconnect
      gnomeExtensions.appindicator
      gnomeExtensions.espresso
      materia-theme
      papirus-icon-theme
    ];
    # gsconnect
    networking.firewall = rec {
      allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };

    programs.dconf.enable = true;
    services.xserver = {
      enable = true;
      layout = "us";
      desktopManager.gnome.enable = true;
      displayManager = {
        gdm = {
          enable = true;
          wayland = false;
          nvidiaWayland = false;
        };
      };
      videoDrivers = [ "nvidia" ];
    };
    services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];
    services.gnome = {
      core-utilities.enable = false;
      core-developer-tools.enable = false;
      evolution-data-server.enable = true;
      gnome-online-accounts.enable = false;
      gnome-keyring.enable = true;
    };

    fonts = {
      fonts = with pkgs; [
        jetbrains-mono
        sarasa-gothic
        apple-emoji
        noto-fonts
        noto-fonts-cjk
        wqy_microhei
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
        enabled = "ibus";
        ibus.engines = with pkgs.ibus-engines; [ rime ];
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
