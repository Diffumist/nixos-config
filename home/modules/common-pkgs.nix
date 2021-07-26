{ lib, pkgs, ... }: {
  home.packages = with pkgs;
    map lib.lowPrio [
      # Console
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
      loop
      gnupg
      file
      rsync
      libarchive
      runzip
      trash-cli
      pandoc
      # GUI
      authy
      typora
      steam
      winetricks
      obs-studio
      neovim
      taisei
      citra
      jetbrains.idea-ultimate
      jetbrains.clion
      jetbrains.goland
      discord
      tdesktop
      weechat
      cantata
      # Dev
      cachix
      patchelf
      gcc
      gdb
      gnumake
      cmake
      lld
      binutils
      python3
      nixpkgs-review
      nixpkgs-fmt
      pkg-config
    ];
}
