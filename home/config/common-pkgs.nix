{ lib, pkgs, config, ... }:
{
  # set implicitly installed packages to be low-priority.
  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    xh
    dnsutils
    fd
    duf
    nix-top
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
    tdesktop
    netease-cloud-music-gtk
    qbittorrent-enhanced
    wine
    winetricks
    steam
    taxi
    cawbird
    solaar
    meld
    drawing
    remmina
    celluloid
    wemeet
    ciscoPacketTracer7
    # Env
    nodejs
    python3
    jdk
    python3.pkgs.pygobject3
    patchelf
    binutils
  ];
}
