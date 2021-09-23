{ lib, config, pkgs, ... }:
with lib; {
  environment.systemPackages = with pkgs; [
    (ark.override { unfreeEnableUnrar = true; })
    gparted
    kdeconnect
    spectacle
    latte-dock
    capitaine-cursors
    materia-theme
    materia-kde-theme
    # FIXME: https://github.com/NixOS/nixpkgs/issues/82769
    libsForQt5.qtstyleplugin-kvantum
    papirus-icon-theme
  ];

  # services.gnome.gnome-keyring.enable = true;

  services.xserver = {
    enable = true;
    layout = "us";
    desktopManager.plasma5.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.settings = {
      Autologin = {
        User = "diffumist";
        Session = "plasma5";
      };
    };
    videoDrivers = [ "nvidia" ];
  };

  security.pam.services.sddm.enableKwallet = true;

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
