{ lib, pkgs, ... }:
{
  # set implicitly installed packages to be low-priority.
  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    xh
    nixpkgs-fmt
    nixpkgs-review
    wgcf
    typst
    typst-fmt
    darkman
    btop
    # GUI
    # jetbrains.idea-ultimate
    kotatogram-desktop
    spotify-tui
    qbittorrent
    transgui
    wine
    winetricks
    logseq
    meld
    # Env
    patchelf
    # LSP
    gopls
    nodePackages.bash-language-server
    nodePackages.vscode-json-languageserver
    nil
    pyright
    typst-lsp
  ];
}
