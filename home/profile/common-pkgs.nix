{ lib, pkgs, ... }:
{
  # set implicitly installed packages to be low-priority.
  home.packages =
    with pkgs;
    map lib.lowPrio [
      # CLI
      wgcf
      typst
      nix-update
      nix-init
      nixfmt-rfc-style
      nixpkgs-review
      yubikey-manager
      # GUI
      jetbrains.idea-ultimate
      # jetbrains.goland
      # jetbrains.clion
      kotatogram-desktop
      localsend
      spotify
      qbittorrent-enhanced
      logseq
      meld
      # LSP
      gopls
      nodePackages.bash-language-server
      nodePackages.vscode-json-languageserver
      nil
      pyright
      typst-lsp
      typst-fmt
    ];
}
