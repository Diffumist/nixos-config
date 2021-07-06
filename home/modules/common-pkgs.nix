{ lib, pkgs, ... }:
{
  home.packages = with pkgs; map lib.lowPrio [
    # Console
    neofetch
    htop
    ncdu
    lsof
    dnsutils
    exa
    fd
    ripgrep
    zoxide
    tealdeer
    man-pages
    jq
    loop
    gnupg
    file
    rsync
    libarchive
    runzip
    trash-cli
    # GUI
    (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
    solaar
    typora
    # firefox mpv <- in module
    steam
    obs-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    tdesktop
    weechat
    cantata
    kate
    # env
    cachix
    patchelf
    gcc
    gdb
    gnumake
    cmake
    lld
    openjdk11
    mono
    binutils
    ghc
    nodejs
    python3
    nixpkgs-review
    nixpkgs-fmt
    pkg-config
  ];
}
