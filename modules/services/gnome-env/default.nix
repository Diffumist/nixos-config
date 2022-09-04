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
        gnome.eog
        gnome.ghex
        gnome.geary
        libreoffice
        virt-manager
        gnome.nautilus-python
        gnome.gnome-tweaks
        gnome.gnome-power-manager
        gnome.gnome-system-monitor
        gnomeExtensions.gsconnect
        gnomeExtensions.appindicator
        gnomeExtensions.espresso
        gnomeExtensions.color-picker
        gnomeExtensions.simple-net-speed
        materia-theme
        papirus-icon-theme
        capitaine-cursors
        shared-mime-info
        nautilus-open-any-terminal
      ];

      services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];
      services.gnome = {
        core-utilities.enable = true;
        core-developer-tools.enable = true;
        evolution-data-server.enable = true;
        gnome-keyring.enable = true;
        glib-networking.enable = true;
      };

      services.printing.enable = false;

      programs = {
        gpaste.enable = true;
      };

      services.xserver = {
        enable = true;
        layout = "us";
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
          noto-fonts-emoji
          noto-fonts-cjk
          (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        ];

        fontDir.enable = true;

        fontconfig = {
          defaultFonts = rec {
            monospace = [ "Jetbrains Mono" ];
            sansSerif = [ "Sarasa Gothic SC" ];
            serif = sansSerif;
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };

      i18n = {
        defaultLocale = "zh_CN.UTF-8";
        supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8" ];

        inputMethod = {
          enabled = "ibus";
          ibus.engines = with pkgs.ibus-engines; [ rime ];
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
