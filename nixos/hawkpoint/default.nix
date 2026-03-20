{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    ../common/nixconfig.nix
    ../common/kernel.nix
    ./boot.nix
    ./hardware.nix
  ];

  nix.channel.enable = false;

  networking = {
    nftables.enable = true;
    firewall.enable = false;
    hostName = "HawkPoint";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless.iwd.settings = {
      PowerSaving = {
        PowerSave = "off";
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
    ];
  };

  environment.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  fonts = {
    packages = with pkgs; [
      sarasa-gothic
      nerd-fonts.fira-code
      apple-emoji-font
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = rec {
        monospace = [ "Fira Code Nerd Font" ];
        sansSerif = [ "Sarasa Gothic SC" ];
        serif = sansSerif;
        emoji = [ "Apple Color Emoji" ];
      };
    };
  };
  # rime
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [
            rime-data
            uncategorized.rime-ice
            uncategorized.rime-moegirl
            uncategorized.rime-zhwiki
          ];
        })
        libsForQt5.fcitx5-qt
        kdePackages.fcitx5-qt
        fcitx5-gtk
        fcitx5-material-color
      ];
      waylandFrontend = true;
    };
  };
  users.users.diffumist = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "storage"
      "podman"
      "networkmanager"
    ];
    initialHashedPassword = config.sops.secrets.user_passwd_hash.path;
    shell = pkgs.fish;
  };
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.user_passwd_hash = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };
  # niri
  programs.niri = {
    enable = true;
    useNautilus = true;
  };
  security.soteria.enable = true;
  services.displayManager.dms-greeter = {
    enable = true;
    configHome = "/home/diffumist";
    compositor.name = "niri";
  };
  services.envfs.enable = true;
  # TODO upstream https://github.com/Mic92/envfs/issues/203
  fileSystems."/usr/bin".options = lib.mkIf config.boot.initrd.systemd.enable [
    "x-systemd.requires=modprobe@fuse.service"
    "x-systemd.after=modprobe@fuse.service"
  ];
  fileSystems."/bin".enable = lib.mkIf config.boot.initrd.systemd.enable false;
  boot.initrd.systemd.tmpfiles.settings = lib.mkIf config.boot.initrd.systemd.enable {
    "50-usr-bin" = {
      "/sysroot/usr/bin" = {
        d = {
          group = "root";
          mode = "0755";
          user = "root";
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [
    # CLI
    duf
    dua
    lstr
    tokei
    rclone
    binutils
    dnsutils
    pciutils
    dnscontrol
    libarchive
    # GUI
    eog
    glib
    adw-gtk3
    nwg-look
    nautilus
    code-nautilus
    mission-center
    seahorse
    pinentry-gnome3
    gsettings-desktop-schemas
    papirus-icon-theme
    polkit_gnome
    gnome-text-editor
    gpu-screen-recorder
    xwayland-satellite
  ];

  programs = {
    dms-shell.enable = true;
    nix-ld.enable = true;
    nexttrace.enable = true;
    nh.enable = true;
    fish = {
      enable = true;
      useBabelfish = true;
    };
    clash-verge = {
      enable = true;
      tunMode = true;
      serviceMode = true;
    };
    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {
          HOME = "${config.users.users.diffumist.home}/.local/share/steam_home";
        };
      };
      extest.enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      gamescopeSession.enable = true;
    };
  };
  services.samba = {
    enable = true;
    settings = {
      global = {
        "invalid users" = [
          "root"
        ];
        "passwd program" = "/run/wrappers/bin/passwd %u";
        security = "user";
        "hosts allow" = "192.168.0. 127.0.0.1";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "workgroup" = "WORKGROUP";
        "netbios name" = "hawkpoint-smb";
        "server string" = "NixOS-Samba";
      };
      public = {
        browseable = "yes";
        path = "/run/media/diffumist";
        "guest ok" = "no";
        "read only" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "diffumist";
      };
    };
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.diffumist = import ./home;
    extraSpecialArgs = { inherit inputs; };
    sharedModules = [
      inputs.nix-index-database.homeModules.default
      inputs.sops-nix.homeManagerModules.sops
    ];
  };
}
