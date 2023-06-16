{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
      # tweak
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      tender-vim
      luasnip
      vim-lastplace
      editorconfig-nvim
      lualine-nvim
      which-key-nvim
      lualine-lsp-progress
    ];
    extraConfig = '':source ${./nvim.lua}'';
  };
  # LSP
  home.packages = with pkgs; [
    gopls
    nodePackages.bash-language-server
    nodePackages.vscode-json-languageserver
    nil
    pyright
    typst-lsp
  ];
}