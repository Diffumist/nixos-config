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
    wl-clipboard
    # GUI
    # jetbrains.idea-ultimate
    tdesktop
    spotify-tui
    qbittorrent
    transgui
    chatbox-bin
    wine
    winetricks
    logseq
    solaar
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
