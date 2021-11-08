{ lib, pkgs, config, ... }:
let
  inherit (config.xdg) configHome;
in
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
    # GUI
    # authy
    obs-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    android-studio
    discord
    kotatogram-desktop
    qbittorrent-enhanced
    wine
    winetricks
    steam
    nur.repos.linyinfeng.wemeet
    # TODO: Modify WPS file icon https://wiki.archlinux.org/title/WPS_Office
    wpsoffice
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
    dosbox
  ];
}
