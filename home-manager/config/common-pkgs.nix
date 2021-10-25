{ lib, pkgs, config, ... }:
let
  theme-path = "${config.xdg.configHome}/Kvantum/MateriaDark/";
  kvantum-patch = pkgs.writeShellScriptBin "kvantum-patch" ''
    if [ ! -d "${theme-path}" ]; then
      mkdir -p ${theme-path}
    fi
    if [ -d "${theme-path}" ]; then
      for file in ${theme-path}/*
      do
        unlink $file
      done
    fi
    ln -s ${pkgs.materia-kde-theme}/share/Kvantum/MateriaDark/* ${theme-path}
  '';
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
    prime-run
    nali
    kvantum-patch
    # GUI
    authy
    obs-studio
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    android-studio
    discord
    kotatogram-desktop
    qbittorrent-enhanced
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
    go
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
