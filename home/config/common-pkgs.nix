{ lib, pkgs, ... }:
{
  # set implicitly installed packages to be low-priority.
  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    xh
    nix-update
    nix-init
    nixfmt-rfc-style
    nixpkgs-review
    ncdu
    wgcf
    typst
    typst-fmt
    btop
    comma
    yubikey-manager
    # GUI
    # jetbrains.idea-ultimate
    tdesktop
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
