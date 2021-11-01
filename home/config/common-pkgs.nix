{ lib, pkgs, config, ... }:
let
  inherit (config.xdg) configHome;
  MateriaDark = "${configHome}/Kvantum/MateriaDark/";
  kvantum-patch = pkgs.writeShellScriptBin "kvantum-patch" ''
    if [ ! -d "${MateriaDark}" ]; then
      mkdir -p ${MateriaDark}
    fi
    if [ -d "${MateriaDark}" ]; then
      for file in ${MateriaDark}/*
      do
        unlink $file
      done
    fi
    ln -s ${pkgs.materia-kde-theme}/share/Kvantum/MateriaDark/* ${MateriaDark}
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
    traceroute
    kvantum-patch

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
    virt-manager
    wine
    winetricks
    steam
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
    deploy-rs.deploy-rs
    nvfetcher
  ];
}