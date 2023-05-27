{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.modules.gnome-env;
in
{
  options.modules.gnome-env = {
    enable = mkEnableOption "GNOME";
    waylandEnable = mkEnableOption "GNOME on wayland";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = with pkgs; [
        gparted
        onlyoffice-bin
        gnome.dconf-editor
        gnome.nautilus-python
        gnome.gnome-tweaks
        gnome.gnome-power-manager
        gnome.gnome-system-monitor
        gnomeExtensions.gsconnect
        gnomeExtensions.appindicator
        gnomeExtensions.espresso
        papirus-icon-theme
        capitaine-cursors
        shared-mime-info
        hicolor-icon-theme
      ];

      environment.gnome.excludePackages = with pkgs.gnome; [
        gnome-weather
        gnome-clocks
        gnome-contacts
        gnome-characters
        gnome-font-viewer
        gnome-logs
        yelp
        totem
        cheese
        epiphany
        simple-scan
        gnome-maps
        gnome-music
        pkgs.gnome-tour
        pkgs.gnome-photos
        pkgs.gnome-console
        pkgs.gnome-connections
      ];

      services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
      services.gnome = {
        core-utilities.enable = true;
        core-developer-tools.enable = mkForce false;
        evolution-data-server.enable = mkForce false;
        gnome-keyring.enable = true;
        glib-networking.enable = mkForce false;
        gnome-initial-setup.enable = mkForce false;
      };

      services.printing.enable = false;

      programs = {
        gpaste.enable = true;
        geary.enable = mkForce false;
      };

      services.xserver = {
        enable = true;
        layout = "us";
        excludePackages = [ pkgs.xterm ];
        desktopManager.gnome.enable = true;
        displayManager = {
          gdm = {
            enable = true;
            wayland = false;
          };
        };
      };

      fonts = {
        fonts = with pkgs; [
          jetbrains-mono
          sarasa-gothic
          apple-emoji
          noto-fonts-cjk
          (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        ];

        fontDir.enable = true;

        fontconfig = {
          defaultFonts = rec {
            monospace = [ "Jetbrains Mono" ];
            sansSerif = [ "Sarasa Gothic SC" ];
            serif = sansSerif;
            emoji = [ "Apple Emoji" ];
          };
        };
      };

      i18n = {
        defaultLocale = "zh_CN.UTF-8";
        supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8" ];

        inputMethod = {
          enabled = "fcitx5";
          fcitx5.addons = with pkgs; [
            fcitx5-chinese-addons
            fcitx5-pinyin-zhwiki
            fcitx5-pinyin-moegirl
            fcitx5-material-color
          ];
        };
      };

      networking = {
        networkmanager = {
          enable = true;
          wifi = {
            backend = "wpa_supplicant";
            macAddress = "preserve";
          };
        };
        # gsconnect
        firewall = rec {
          allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
          allowedUDPPortRanges = allowedTCPPortRanges;
        };
      };
    })

    (mkIf cfg.waylandEnable {
      services.xserver.displayManager.gdm = {
        wayland = mkForce true;
        nvidiaWayland = true;
      };
    })
  ]);
}
