{ lib, pkgs, ... }:
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
    nixpkgs-review
    wgcf
    # GUI
    # jetbrains.idea-ultimate
    jetbrains.clion
    # jetbrains.goland
    tdesktop
    spotify-tui
    qbittorrent
    chatbox-bin
    wine
    winetricks
    obsidian
    solaar
    meld
    # Env
    patchelf
    binutils
  ];
}
