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
    libarchive
    nixpkgs-fmt
    yubikey-manager
    prime-run
    frp
    # GUI
    # jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    jetbrains.pycharm-professional
    jetbrains.webstorm
    # android-studio
    tdesktop
    spotify
    # qbittorrent-enhanced
    wine
    winetricks
    steam
    obsidian
    solaar
    meld
    wemeet
    # Env
    nodejs
    python3
    patchelf
    binutils
  ];
}
