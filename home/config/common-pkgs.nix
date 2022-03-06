{ lib, pkgs, config, ... }:
{
  # set implicitly installed packages to be low-priority.
  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    xh
    dnsutils
    fd
    duf
    ripgrep
    man-pages
    hyperfine
    libarchive
    nixpkgs-fmt
    yubikey-manager
    prime-run
    ydcv-rs
    # GUI
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    android-studio
    nur.repos.ilya-fedin.kotatogram-desktop
    netease-cloud-music-gtk
    qbittorrent-enhanced
    yuzu
    wine
    winetricks
    steam
    citra
    taxi
    cawbird
    solaar
    ciscoPacketTracer7
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
