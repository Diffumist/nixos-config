{ config, pkgs, ... }:
let
  xdgdirs = {
    # cache
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.cacheHome}/java";
    # config
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    # data
    WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    NALI_DB_HOME = "${config.xdg.dataHome}/nali";
    # state
    HISTFILE = "${config.xdg.stateHome}/bash_history";
    LESSHISTFILE = "${config.xdg.stateHome}/lesshst";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
  };
in
{
  # dconf.settings = import ./dconf.nix { };
  xdg = {
    userDirs = {
      enable = true;
      publicShare = "$HOME";
      templates = "$HOME";
      videos = "$HOME";
    };
    mime.enable = true;
    configFile = {
      "gnome-initial-setup-done".text = "yes";
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
      "dosbox/dosbox.conf".text = ''
        [sdl]
        windowresolution=1080x800
        output=opengl
      '';
      "containers/storage.conf".text = ''
        [storage]
        driver = "btrfs"
      '';
      "fcitx5/conf/classicui.conf".text = ''
        Vertical Candidate List=False
        Font="Noto Sans CJK SC 10"
        UseInputMethodLangaugeToDisplayText=True
        Theme=Material-Color-Black
      '';
    };
    dataFile = {
      "cargo/config".text = ''
        [source.crates-io]
        replace-with = 'sjtu'
        [source.sjtu]
        registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index/"
      '';
    };
  };
  gtk = {
    enable = true;
    font = { name = "Sarasa Gothic SC"; size = 11; };
    iconTheme = { name = "Papirus"; };
    theme = { name = "Materia"; };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.bookmarks = [
      "file:///home/diffumist/Documents/Project"
      "file:///home/diffumist/Documents/School"
      "file:///home/diffumist/Documents/Book"
      "file:///home/diffumist/Documents/Note"
    ];
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
    style = { package = pkgs.adwaita-qt; name = "adwaita"; };
  };
  systemd.user.sessionVariables = xdgdirs;
  xresources.path = "${config.xdg.dataHome}/Xresources";
}
