{ pkgs, lib, ... }:
let
  material-nvim = pkgs.vimUtils.buildVimPlugin rec {
    pname = "material-nvim";
    version = "2021-10-15";
    src = pkgs.fetchgit {
      url = "https://github.com/marko-cerovac/material.nvim";
      rev = "f8e663ae7b185e64acad94b72914c88fda729cf5";
      sha256 = "KydXkdDF5bkUC5pJ0ydyixUYTqE0zPa6iLeGmTpibHM=";
    };
  };
in
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      lualine-nvim
      dashboard-nvim
      bufferline-nvim
      toggleterm-nvim
      material-nvim
      # lsp
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      nvim-lspconfig
      lsp_signature-nvim
      lspkind-nvim
      # tweak
      neoformat
      direnv-vim
      nvim-treesitter
      nvim-web-devicons
      nvim-tree-lua
      neoscroll-nvim
      nvim-autopairs
      cheatsheet-nvim
      indent-blankline-nvim
      telescope-nvim
      telescope-fzf-native-nvim
    ];
    extraConfig = builtins.readFile ./setting.vimrc;
  };
}
