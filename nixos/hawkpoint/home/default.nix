{
  pkgs,
  config,
  inputs,
  ...
}:
{
  # services
  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableExtraSocket = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };
  systemd.user.services.cli-proxy-api = {
    Unit = {
      Description = "CLIProxyAPI Service";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.cli-proxy-api}/bin/cli-proxy-api --config %h/.local/share/cli-proxy-api/config.yaml";
    };
  };
  # programs
  programs = {
    home-manager.enable = true;
    zoxide.enable = true;
    fzf.enable = true;
    ripgrep.enable = true;
    fd.enable = true;
    fastfetch.enable = true;
    nix-index-database.comma.enable = true;
    btop.enable = true;
    uv.enable = true;
    go = {
      enable = true;
      env = {
        GOPATH = "${config.xdg.cacheHome}/go";
        GOBIN = "${config.home.homeDirectory}/.local/bin";
      };
    };
    eza = {
      enable = true;
      git = true;
    };
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
        style = "changes,header";
      };
    };
    fish = {
      enable = true;
      shellInit = ''
        set -g fish_greeting
      '';
    };
    starship = {
      enable = true;
      settings = {
        battery.disabled = true;
        directory = {
          read_only_style = "green";
          truncation_length = 3;
          truncation_symbol = "…/";
        };
      };
    };
    direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      stdlib = ''
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
          echo "''${direnv_layout_dirs[$PWD]:=$(
            echo -n "$XDG_CACHE_HOME"/direnv/layouts/
            echo -n "$PWD" | sha1sum | cut -d ' ' -f 1
          )}"
        }
      '';
    };
    yazi = {
      enable = true;
      shellWrapperName = "yy";
    };
    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
    };
    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "noctalia";
        editor = {
          line-number = "relative";
          trim-final-newlines = true;
        };
      };
      themes = { };
    };
    ghostty = {
      enable = true;
      settings = {
        theme = "noctalia";
      };
      themes = {
        noctalia = {
          background = "#131313";
          foreground = "#e2e2e2";
          cursor-color = "#e2e2e2";
          cursor-text = "#131313";
          selection-background = "#d3bfe6";
          selection-foreground = "#382a49";
          palette = [
            "0 = #474747"
            "1 = #ffb4ab"
            "2 = #97cbff"
            "3 = #b9c8da"
            "4 = #d3bfe6"
            "5 = #97cbff"
            "6 = #b9c8da"
            "7 = #e2e2e2"
            "8 = #c6c6c6"
            "9 = #ffb4ab"
            "10 = #97cbff"
            "11 = #b9c8da"
            "12 = #d3bfe6"
            "13 = #97cbff"
            "14 = #b9c8da"
            "15 = #e2e2e2"
          ];
        };
      };
    };
    git = {
      enable = true;
      ignores = [
        ".vscode"
        ".DS_store"
      ];
      settings = {
        user.name = "Diffumist";
        user.email = "git@diffumist.me";
      };
      signing = {
        signByDefault = true;
        key = "8BA330B49A5694A6";
      };
    };
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      settings.default-key = "8BA330B49A5694A6";
      scdaemonSettings.deny-admin = true;
    };
    lazygit.enable = true;
    chromium = {
      enable = true;
      commandLineArgs = [
        "--ozone-platform=wayland"
        "--enable-features=VaapiVideoDecodeLinuxGL"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
      ];
    };
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      profiles.default.extensions = with pkgs.vscode-marketplace; [
        golang.go
        mkhl.direnv
        docker.docker
        oxc.oxc-vscode
        jnoortheen.nix-ide
        rust-lang.rust-analyzer
        piousdeer.adwaita-theme
        pkief.material-icon-theme
        pkief.material-product-icons
        ms-python.python
        ms-python.debugpy
        ms-python.vscode-python-envs
        ms-ceintl.vscode-language-pack-zh-hans
      ];
    };
  };
  home.packages = with pkgs; [
    # CLI
    xh
    tokei
    age
    sops
    nixd
    nixfmt
    gdb
    gcc
    cmake
    gnumake
    ninja
    deno
    oxfmt
    oxlint
    tsgolint
    nodejs
    rustup
    python3
    nix-init
    patchelf
    steam-run
    hyperfine
    dnscontrol
    bubblewrap
    pkg-config
    android-tools
    nixpkgs-review
    systemd-run-app
    nix-output-monitor
    # TUI
    inputs.codex-cli-nix.packages.${pkgs.system}.default
    # opencode
    gemini-cli-bin
    # claude-code
    # GUI
    qq
    wemeet
    kazumi
    splayer
    vesktop
    gapless
    clapper
    localsend
    fluffychat
    antigravity-fhs
    ayugram-desktop
    qbittorrent-enhanced
    # uncategorized.dingtalk
  ];

  # XDG dir
  # nix run github:b3nj5m1n/xdg-ninja
  xdg = {
    enable = true;
    userDirs = {
      desktop = "$HOME/Desktop";
      download = "$HOME/Downloads";
      pictures = "$HOME/Pictures";
      documents = "$HOME/Documents";
      music = "$HOME/Music";
      videos = "$HOME/Video";
      publicShare = "$HOME";
      templates = "$HOME";
    };
    mimeApps.enable = true;
    portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;
      config.common.default = "*";
    };
    autostart.readOnly = true;
    configFile = {
      "npm/npmrc".text = ''
        prefix=${config.xdg.dataHome}/npm
        cache=${config.xdg.cacheHome}/npm
        init-module=${config.xdg.cacheHome}/npm/config/npm-init.js
        logs-dir=${config.xdg.stateHome}/npm/logs
      '';
    };
    dataFile = {
      "fcitx5/rime/default.custom.yaml".text = ''
        patch:
          __include: rime_ice_suggestion:/
          schema_list:
            - schema: rime_ice
          rime_ice.dict/import_tables/+:
            - zhwiki.dict
            - moegirl.dict
      '';
    };
  };
  fonts.fontconfig = {
    enable = true;
    hinting = "full";
    antialiasing = true;
    subpixelRendering = "rgb";
  };
  gtk = {
    enable = true;
    font = {
      name = "Sarasa Gothic SC";
      size = 12;
    };
    iconTheme.name = "Papirus";
    # cursorTheme.name = "Capitaine Cursors";
    gtk3 = {
      bookmarks = [
        "file://${config.home.homeDirectory}/Projects"
        "file://${config.home.homeDirectory}/Downloads"
        "file://${config.home.homeDirectory}/Documents"
        "file://${config.home.homeDirectory}/Pictures"
        "file://${config.home.homeDirectory}/Music"
        "file://${config.home.homeDirectory}/Videos"
      ];
      extraConfig.gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
  home.sessionVariables = {
    # xdg dir base
    XDG_CONFIG_HOME = "${config.xdg.configHome}";
    XDG_CACHE_HOME = "${config.xdg.cacheHome}";
    XDG_DATA_HOME = "${config.xdg.dataHome}";
    XDG_STATE_HOME = "${config.xdg.stateHome}";
    # binary
    PATH = "${config.home.homeDirectory}/.local/bin\${PATH:+:}$PATH";
    # cache
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    # config
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    # data
    FFMPEG_DATADIR = "${config.xdg.dataHome}/ffmpeg";
    WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    CODEX_HOME = "${config.xdg.dataHome}/codex";
    # state
    HISTFILE = "${config.xdg.stateHome}/bash/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/history";
  };
  xresources.path = "${config.xdg.dataHome}/Xresources";
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
        fcitx5-gtk
      ];
      waylandFrontend = true;
    };
  };
  home.shell.enableFishIntegration = true;
  home.preferXdgDirectories = true;
  home.stateVersion = "25.11";
}
