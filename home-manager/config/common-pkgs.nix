{ lib, pkgs, ... }: {
  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    neofetch
    htop
    ncdu
    lsof
    dnsutils
    fd
    tealdeer
    man-pages
    jq
    gnupg
    file
    rsync
    libarchive
    runzip
    pandoc
    # GUI
    authy
    obs-studio
    neovim
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.rider
    tdesktop
    qbittorrent-enhanced
    google-chrome
    steam
    citra
    (wine.override { wineRelease = "unstable"; })
    (winetricks.override { wine = wine.override { wineRelease = "unstable"; }; })
    # Env
    patchelf
    gcc
    gdb
    gnumake
    cmake
    lld
    binutils
    python3
    mono
    nixpkgs-review
    nixpkgs-fmt
    pkg-config
  ];
}
