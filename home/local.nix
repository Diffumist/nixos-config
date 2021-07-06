{ pkgs, config, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ./modules/alacritty.nix
    ./modules/common-pkgs.nix
    ./modules/direnv.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/fcitx5.nix
    ./modules/mpv.nix
    ./modules/chromium.nix
    # ./modules/rust.nix
    ./modules/shell/default.nix
    ./modules/trash.nix
    ./modules/user-dirs.nix
    ./modules/vscode

  ];

  fonts.fontconfig.enable = true;

  # FIXME: sddm doesn't respect `home.sessionVariables`.
  # systemd.user.sessionVariables = {
  #   inherit (config.home.sessionVariables) CARGO_HOME GNUPGHOME;
  # };
  systemd.user.sessionVariables = {
    inherit (config.home.sessionVariables)
      GNUPGHOME;
    CACHIX_AUTH_TOKEN = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1JDExODQ5IiwianRpIjoiNmY0ZDdhOWItNjAzOS00YTQxLWI4OTctYzllMWY2Y2E5MDkyIiwic2NvcGVzIjoidHgifQ.7XfhGJIW-bEFuSpLXV0ioGSlJqif7qIdn_P0VkyeCc8";
    LIBVA_DRIVER_NAME = "iHD";
    # cache
    XCOMPOSECACHE = "${config.xdg.cacheHome}/compose";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.cacheHome}/java";
    MYSQL_HISTFILE = "${config.xdg.cacheHome}/mysql_history";
    NODE_REPL_HISTORY = "${config.xdg.cacheHome}/node_repl_history";
    HISTFILE = "${config.xdg.cacheHome}/bash_history";
    # data
    WAKATIME_HOME = "${config.xdg.dataHome}/wakatime";
    WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";
    VSCODE_PORTABLE = "${config.xdg.dataHome}/vscode";
    GTK2_RC_FILES = "${config.xdg.dataHome}/gtk-2.0/gtkrc";
    CABAL_DIR = "${config.xdg.dataHome}/cabal";
    CABAL_CONFIG = "${config.xdg.dataHome}/cabal/config";
    KDEHOME = "${config.xdg.dataHome}/kde";
    LESSHISTFILE = "${config.xdg.dataHome}/lesshst";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.03";
}
