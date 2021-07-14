{ config, ... }:
let
  xdgdirs = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
    LIBVA_DRIVER_NAME = "iHD";
    # WIP: https://github.com/rust-windowing/winit/pull/1963
    WINIT_X11_SCALE_FACTOR="1.5";
    # cache
    XCOMPOSECACHE = "${config.xdg.cacheHome}/compose";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    MYSQL_HISTFILE = "${config.xdg.cacheHome}/mysql_history";
    NODE_REPL_HISTORY = "${config.xdg.cacheHome}/node_repl_history";
    HISTFILE = "${config.xdg.cacheHome}/bash_history";
    # config
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    # data
    WAKATIME_HOME = "${config.xdg.dataHome}/wakatime";
    WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";
    GTK2_RC_FILES = "${config.xdg.dataHome}/gtk-2.0/gtkrc";
    CABAL_DIR = "${config.xdg.dataHome}/cabal";
    CABAL_CONFIG = "${config.xdg.dataHome}/cabal/config";
    KDEHOME = "${config.xdg.dataHome}/kde";
    GRADLE_USER_HOME="${config.xdg.dataHome}/gradle";
    LESSHISTFILE = "${config.xdg.dataHome}/lesshst";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
  };
in {
  xdg = {
    userDirs = {
      enable = true;
      desktop = "$HOME/Desktop";
      download = "$HOME/Downloads";
      pictures = "$HOME/Pictures";
      documents = "$HOME/Documents";
      music = "$HOME/Music";
      publicShare = "$HOME";
      templates = "$HOME";
      videos = "$HOME/Videos";
    };
    configFile = {
      "go/env".text = ''
        GOPATH=${config.xdg.cacheHome}/go
        GOBIN=${config.xdg.dataHome}/go/bin
        GO111MODULE=on
        GOPROXY=https://goproxy.cn
        GOSUMDB=sum.golang.google.cn
      '';
      "npm/npmrc".text = ''
        prefix=${config.xdg.dataHome}/npm
        cache=${config.xdg.cacheHome}/npm
        tmp=$XDG_RUNTIME_DIR/npm
        init-module=${config.xdg.configHome}/npm/config/npm-init.js
        store-dir=${config.xdg.dataHome}/pnpm-store
      '';
      "fcitx5/conf/classicui.conf".text = ''
        Vertical Candidate List=False
        Font="Noto Sans CJK SC 10"
        UseInputMethodLangaugeToDisplayText=True
        Theme=Material-Color-Black
      '';
    };
  };
  systemd.user.sessionVariables = xdgdirs;
}
