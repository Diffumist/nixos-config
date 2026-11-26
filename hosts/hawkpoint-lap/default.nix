{
  pkgs,
  lib,
  config,
  inputs,
  self,
  ...
}:
let
  sambaNetbiosNamePort = 137;
  sambaNetbiosDatagramPort = 138;
  sambaNetbiosSessionPort = 139;
  sambaPort = 445;
in
{
  imports = [
    "${self}/profiles/common/nixconfig.nix"
    "${self}/profiles/common/kernel.nix"
    "${self}/modules/system/nixos-init.nix"
    ./boot.nix
    ./hardware.nix
  ];

  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      user_passwd_hash = {
        neededForUsers = true;
      };
      github_access_token = {
        neededForUsers = true;
      };
      sshosts = {
        sopsFile = ./home/sshosts.keytab;
        format = "binary";
        owner = "root";
        group = "wheel";
        mode = "0440";
      };
    };
  };
  programs.ssh.extraConfig = ''
    Include ${config.sops.secrets.sshosts.path}
  '';
  nix = {
    channel.enable = false;
    settings.substituters = lib.mkAfter [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
    ];
    settings.builders-use-substitutes = true;
    settings.extra-substituters = [
      "https://umbriel.cachix.org"
      "https://noctalia.cachix.org"
    ];
    settings.extra-trusted-public-keys = [
      "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
    extraOptions = ''
      !include ${config.sops.secrets.github_access_token.path}
    '';
  };
  networking = {
    nftables.enable = true;
    firewall.enable = false;
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
      "en_US.UTF-8/UTF-8"
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

  fonts = {
    packages = with pkgs; [
      sarasa-gothic
      wqy_microhei
      maple-mono.NF-CN-unhinted
      apple-emoji-font
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = rec {
        monospace = [ "Maple Mono NF CN" ];
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
      "podman"
      "greeter"
      "storage"
      "networkmanager"
    ];
    hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
    shell = pkgs.fish;
  };
  programs.umbriel.enable = true;
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
    systemd = {
      enable = true;
      target = "umbriel-session.target";
    };
  };
  # Umbriel waits for graphical-session.target, so ordering Noctalia before it creates a cycle.
  systemd.user.services.noctalia.before = lib.mkForce [ ];
  security = {
    polkit.enable = true;
    sudo.enable = false;
    run0 = {
      enable = true;
      sudo-shim.enable = true;
      persistentAuth.enable = true;
    };
  };
  services.displayManager.noctalia-greeter = {
    enable = true;
    settings.keyboard = {
      layout = "us";
      numlock = true;
    };
  };
  xdg.portal = {
    xdgOpenUsePortal = true;
    config.umbriel."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };
  services.gnome.gnome-keyring.enable = true;
  services.envfs.enable = true;
  environment.systemPackages = with pkgs; [
    # CLI
    duf
    xsz
    dua
    # lstr
    tokei
    rclone
    binutils
    dnsutils
    pciutils
    dnscontrol
    libarchive
    # GUI
    loupe
    glib
    adw-gtk3
    nwg-look
    nautilus
    seahorse
    resources
    file-roller
    code-nautilus
    cups-pk-helper
    pinentry-gnome3
    gsettings-desktop-schemas
    papirus-icon-theme
    gnome-text-editor
    gpu-screen-recorder
  ];

  programs = {
    nix-ld.enable = true;
    nexttrace.enable = true;
    fish = {
      enable = true;
      useBabelfish = true;
    };
    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };
    nh = {
      enable = true;
      flake = "${config.users.users.diffumist.home}/Projects/nixos-config";
    };
    steam = {
      enable = true;
      package = pkgs.steam.override {
        # Waylith searches fixed CJK font paths instead of consulting fontconfig.
        extraPkgs = pkgs: [
          (pkgs.linkFarm "steam-cjk-font-path" [
            {
              name = "share/fonts/truetype/wqy/wqy-microhei.ttc";
              path = "${pkgs.wqy_microhei}/share/fonts/truetype/wqy-microhei.ttc";
            }
          ])
        ];
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
  services.mihomo = {
    enable = true;
    tunMode = true;
    processesInfo = true;
    webui = pkgs.metacubexd;
    configFile = "/var/lib/mihomo.yaml";
  };
  security.pam.services.login.enableGnomeKeyring = true;
  services.angrr = {
    enable = true;
    settings = {
      profile-policies = {
        system = {
          keep-booted-system = true;
          keep-current-system = true;
          keep-latest-n = 5;
          keep-since = "14d";
          profile-paths = [
            "/nix/var/nix/profiles/system"
          ];
        };
        user = {
          enable = true;
          keep-booted-system = false;
          keep-current-system = false;
          keep-latest-n = 1;
          keep-since = "1d";
          profile-paths = [
            "~/.local/state/nix/profiles/profile"
            "/nix/var/nix/profiles/per-user/root/profile"
          ];
        };
      };
      temporary-root-policies = {
        direnv = {
          path-regex = "/\\.direnv/";
          period = "14d";
        };
        result = {
          path-regex = "/result[^/]*$";
          period = "3d";
        };
      };
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
        "smb ports" = "${toString sambaNetbiosSessionPort} ${toString sambaPort}";
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
  security.pki.certificateFiles = [
    "${pkgs.dn42-cacert}/etc/ssl/certs/dn42-ca.crt"
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.diffumist = import ./home;
    sharedModules = [
      inputs.nix-index-database.homeModules.default
      inputs.umbriel.homeModules.default
      inputs.noctalia.homeModules.default
    ];
  };

  my.networking = {
    usedTCPPorts = {
      aria2-rpc = config.home-manager.users.diffumist.programs.aria2.settings.rpc-listen-port;
      samba-netbios-session = sambaNetbiosSessionPort;
      samba-smb = sambaPort;
    };
    usedUDPPorts = {
      samba-netbios-datagram = sambaNetbiosDatagramPort;
      samba-netbios-name = sambaNetbiosNamePort;
    };
  };
}
