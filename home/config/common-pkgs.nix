{ lib, pkgs, config, ... }:
{
  # set implicitly installed packages to be low-priority.
  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    curl
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
    gnupg
    file
    rsync
    libarchive
    runzip
    pandoc
    sops
    age
    compsize
    prime-run
    nali
    traceroute
    bubblewrap
    nixpkgs-review
    nixpkgs-fmt
    pkg-config
    deploy-rs.deploy-rs
    nvfetcher
    cachix
    scrcpy
    perlPackages.FileMimeInfo
    dconf2nix
    gjs
    # GUI
    # authy
    # obs-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    android-studio
    kotatogram-desktop
    netease-cloud-music-gtk
    qbittorrent-enhanced
    # wine
    # winetricks
    # steam
    taxi
    cawbird
    # Env
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
