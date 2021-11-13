{ config, pkgs, ... }:
let
  xdgdirs = {
    # cache
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    NODE_REPL_HISTORY = "${config.xdg.cacheHome}/node_repl_history";
    HISTFILE = "${config.xdg.cacheHome}/bash_history";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.cacheHome}/java";
    # config
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    # data
    WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    LESSHISTFILE = "${config.xdg.dataHome}/lesshst";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    NALI_DB_HOME = "${config.xdg.dataHome}/nali";
  };
in
{
  xsession = {
    pointerCursor.package = pkgs.capitaine-cursors;
    pointerCursor.defaultCursor = "capitaine-cursors";
    pointerCursor.name = "capitaine-cursors";
  };
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
      "ibus/rime/default.custom.yaml".text = ''
        patch:
          translator/dictionary: pinyin_simp
          schema_list:
            - schema: luna_pinyin_simp
      '';
      "ibus/rime/pinyin_simp.dict.yaml".text = ''
        ---
        name: pinyin_simp
        version: "0.1"
        sort: by_weight
        use_preset_vocabulary: true
        style:
          horizontal: true
        import_tables:
          - luna_pinyin
          - zhwiki
          - moegirl
        ...
      '';
      "ibus/rime/zhwiki.dict.yaml".source = "${pkgs.rime-pinyin-zhwiki}/share/rime-data/zhwiki.dict.yaml";
      "ibus/rime/moegirl.dict.yaml".source = "${pkgs.rime-pinyin-moegirl}/share/rime-data/moegirl.dict.yaml";
    };
    dataFile = {
      "cargo/config".text = ''
        [source.crates-io]
        replace-with = 'ustc'
        [source.ustc]
        registry = "https://mirrors.ustc.edu.cn/crates.io-index"
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
  home.sessionVariables = xdgdirs;
  xresources.path = "${config.xdg.dataHome}/.Xresources";
}
