{ lib, pkgs, ... }: {
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
    prime-run
    # GUI
    authy
    obs-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    android-studio
    tdesktop
    qbittorrent-enhanced
    steam
    virt-manager
    wine
    winetricks
    # Env
    patchelf
    gcc
    gdb
    gnumake
    cmake
    lld
    binutils
    python3
    nodejs
    mono
    nixpkgs-review
    nixpkgs-fmt
    pkg-config
    # LSP
    nodePackages.typescript-language-server
    nodePackages.prettier
    nodePackages.yaml-language-server
    rnix-lsp
    pyright
    tree-sitter
  ];
}
