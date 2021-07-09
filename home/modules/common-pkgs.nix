{ lib, pkgs, ... }:
{
  home.packages = with pkgs; map lib.lowPrio [
    # Console
    neofetch
    htop
    ncdu
    lsof
    dnsutils
    fd
    ripgrep
    tealdeer
    man-pages
    jq
    loop
    gnupg
    file
    compsize
    rsync
    libarchive
    runzip
    trash-cli
    wakatime
    tabnine
    # GUI
    typora
    # firefox mpv <- in module
    steam
    winetricks
    wine
    obs-studio
    neovim
    taisei
    libdbusmenu
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    tdesktop
    weechat
    cantata
    # Dev
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
