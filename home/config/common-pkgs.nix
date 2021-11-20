{ lib, pkgs, config, ... }:
{
  # set implicitly installed packages to be low-priority.
  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    curl
    dnsutils
    fd
    ripgrep
    man-pages
    libarchive
    nixpkgs-fmt
    # GUI
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    android-studio
    kotatogram-desktop
    netease-cloud-music-gtk
    qbittorrent-enhanced
    wine
    winetricks
    steam
    taxi
    cawbird
    # Env
    pkg-config
    patchelf
    gnumake
    cmake
    lld
    binutils
    python3
    nodejs
    mono
    go
  ];
}
