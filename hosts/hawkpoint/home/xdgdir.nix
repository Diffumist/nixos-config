{ config, pkgs, ... }:
{
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
  gtk = {
    enable = true;
    font = {
      name = "Sarasa Gothic SC";
      size = 12;
    };
    iconTheme.name = "Papirus";
    theme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita";
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3 = {
      theme = {
        package = pkgs.adw-gtk3;
        name = "adw-gtk3";
      };
      bookmarks = [
        "file://${config.home.homeDirectory}/Projects"
        "file://${config.home.homeDirectory}/Downloads"
        "file://${config.home.homeDirectory}/Documents"
        "file://${config.home.homeDirectory}/Pictures"
        "file://${config.home.homeDirectory}/Music"
        "file://${config.home.homeDirectory}/Videos"
      ];
      extraConfig = {
        gtk-decoration-layout = ":none";
        gtk-application-prefer-dark-theme = 1;
      };
    };
    gtk4 = {
      theme = config.gtk.theme;
      extraConfig = {
        gtk-decoration-layout = ":none";
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
  home.sessionVariables = {
    DO_NOT_TRACK = 1;
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
}
