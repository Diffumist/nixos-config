{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.modules.gnome-env;
in
{
  options.modules.gnome-env = {
    enable = mkEnableOption "GNOME";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = with pkgs; [
        kooha
        gparted
        mission-center
        dconf-editor
        nautilus-python
        gnome-tweaks
        gnome-power-manager
        gnome-sound-recorder
        gnomeExtensions.appindicator
        gnomeExtensions.espresso
        gnomeExtensions.unite
        gnomeExtensions.blur-my-shell
        gnomeExtensions.dash-to-dock
        papirus-icon-theme
        capitaine-cursors
        shared-mime-info
        hicolor-icon-theme
      ];

      environment.gnome.excludePackages = with pkgs; [
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
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      services.udev.packages = with pkgs; [ gnome-settings-daemon ];
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
        thunderbird = {
          enable = true;
          preferencesStatus = "default";
        };
      };

      services.xserver = {
        enable = true;
        xkb.layout = "us";
        excludePackages = [ pkgs.xterm ];
        desktopManager.gnome.enable = true;
        displayManager = {
          gdm = {
            enable = true;
            wayland = true;
          };
        };
      };

      fonts = {
        packages = with pkgs; [
          jetbrains-mono
          sarasa-gothic
          apple-emoji
          noto-fonts-cjk-sans
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
          enable = true;
          type = "fcitx5";
          fcitx5.addons = with pkgs; [
            fcitx5-chinese-addons
            fcitx5-pinyin-zhwiki
            fcitx5-pinyin-moegirl
            fcitx5-material-color
          ];
        };
      };

      networking = {
        wireless.iwd = {
          enable = true;
          settings = {
            Network = {
              EnableIPv6 = true;
              RoutePriorityOffset = 300;
            };
            Settings = {
              AutoConnect = true;
            };
          };
        };
        networkmanager = {
          enable = true;
          wifi = {
            backend = "iwd";
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
  ]);
}
