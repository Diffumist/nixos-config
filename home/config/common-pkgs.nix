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
    systemd-run-app
    wgcf
    # GUI
    # jetbrains.idea-ultimate
    jetbrains.clion
    # jetbrains.goland
    jetbrains.pycharm-professional
    # jetbrains.webstorm
    # android-studio
    tdesktop
    spotify
    qbittorrent
    chatbox-bin
    wine
    winetricks
    obsidian
    solaar
    meld
    # Env
    nodejs
    python3
    patchelf
    binutils
  ];
}
