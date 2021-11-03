{ config, ... }:
let
  xdgdirs = {
    # Cache
    XCOMPOSECACHE = "${config.xdg.cacheHome}/compose";
    COMPOSER_CACHE_DIR = "${config.xdg.cacheHome}/compose";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    NODE_REPL_HISTORY = "${config.xdg.cacheHome}/node_repl_history";
    HISTFILE = "${config.xdg.cacheHome}/bash_history";
    # Config
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    # Data
    WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";
    GTK2_RC_FILES = "${config.xdg.dataHome}/gtk-2.0/gtkrc";
    KDEHOME = "${config.xdg.dataHome}/kde";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    LESSHISTFILE = "${config.xdg.dataHome}/lesshst";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    VSCODE_PORTABLE = "${config.xdg.dataHome}/vscode";
    NALI_DB_HOME = "${config.xdg.dataHome}/nali";
  };
in
{
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
      videos = "$HOME";
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
        Font="Sarasa Gothic SC 10"
        UseInputMethodLangaugeToDisplayText=True
        Theme=Material-Color-Black
      '';
      "Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=MateriaDark
      '';
      "latte/Default.layout.latte".source = ./latte.config;
    };
  };
  systemd.user.sessionVariables = xdgdirs;
}
