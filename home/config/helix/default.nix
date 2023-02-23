{ pkgs, lib, ... }: {
  home.packages = with pkgs; [ helix rnix-lsp ];
}
