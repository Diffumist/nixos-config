{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.dmist.gnome-env;
in
{
  options.dmist.gnome-env = {
    enable = mkEnableOption "GNOME";
    waylandEnable = mkEnableOption "GNOME on wayland";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = with pkgs; [
        meld
        srain
        kooha
        evince
        drawing
        remmina
        lollypop
        newsflash
        wpsoffice
        gnome.eog
        gnome.ghex
        gnome.gedit
        gnome.gpaste
        gnome-builder
        gnome.seahorse
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
        capitaine-cursors
      ];

      services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];
      services.gnome = {
        core-utilities.enable = false;
        core-developer-tools.enable = false;
        evolution-data-server.enable = true;
        gnome-online-accounts.enable = false;
        gnome-keyring.enable = true;
      };

      programs = {
        dconf.enable = true;
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
        defaultLocale = "en_US.UTF-8";
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
    (mkIf (cfg.waylandEnable) {
      services.xserver.displayManager.gdm = {
        wayland = mkForce true;
        nvidiaWayland = true;
      };
    })
  ]);
}
