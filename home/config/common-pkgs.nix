{ lib, pkgs, config, ... }:
let
  inherit (config.xdg) configHome;
  MateriaDark = "${configHome}/Kvantum/MateriaDark/";
  kvantum-patch = pkgs.writeShellScriptBin "kvantum-patch" ''
    if [[ ! -d "${MateriaDark}" ]]; then
      mkdir -p ${MateriaDark}
    fi
    if [[ -d "${MateriaDark}" ]]; then
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
    age
    compsize
    prime-run
    nali
    traceroute
    kvantum-patch
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
    virt-manager
    wine
    winetricks
    steam
    nur.repos.linyinfeng.wemeet
    # Env
    patchelf
    gnumake
    cmake
    lld
    llvm_12
    clang_12
    binutils
    python3
    nodejs
    mono
    go
    (rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" ];
      targets = [ "x86_64-unknown-linux-musl" ];
    })
  ];
}
