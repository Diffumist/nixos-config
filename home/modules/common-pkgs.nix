{ lib, pkgs, ... }:
{
  home.packages = with pkgs; map lib.lowPrio [
    # Console
    neofetch
    htop
    pv
    ncdu
    dnsutils
    swapview # Stat
    exa
    fd
    ripgrep
    zoxide
    lsof
    tealdeer
    jq
    loop
    bc
    gnupg
    file
    pwgen
    rsync # Util
    libarchive
    runzip # Compression
    trash-cli # CLI-Desktop
    (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
    # taskwarrior # Task manager
    solaar
    # GUI
    typora
    # firefox mpv <- in module
    steam # Games
    obs-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland # Jetbrains
    tdesktop
    weechat # Messaging
    netease-cloud-music # Music
    # Dev
    man-pages # Man
    cachix
    patchelf # Utils
    gcc
    gdb
    gnumake
    cmake
    lld
    binutils # rust's backtrace-sys requires `ar`
    ghc
    nodejs # myIdris <- broken
    python3 # myPython
    nixpkgs-review # nix

    # sqlite-interactive # sqlite

    ################
    # Keep from GC #
    ################

    # Dev deps
    pkg-config
  ];
}
