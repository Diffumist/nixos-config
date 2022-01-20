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
    libarchive
    nixpkgs-fmt
    yubikey-manager
    prime-run
    # GUI
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    android-studio
    kotatogram-desktop
    netease-cloud-music-gtk
    qbittorrent-enhanced
    # nur.repos.linyinfeng.icalingua
    wine
    winetricks
    steam
    citra
    taxi
    cawbird
    solaar
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
