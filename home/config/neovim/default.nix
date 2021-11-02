{ pkgs, lib, ... }:
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
      pkgs.material-nvim
      # lsp
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      nvim-lspconfig
      lsp_signature-nvim
      lspkind-nvim
      (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
      # tweak
      neoformat
      direnv-vim
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
  # LSP
  home.packages = with pkgs; [
    nodePackages.typescript-language-server
    nodePackages.prettier
    nodePackages.yaml-language-server
    rnix-lsp
    pyright
  ];
}
