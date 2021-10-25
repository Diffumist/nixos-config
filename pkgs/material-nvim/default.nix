{ source, pkgs, lib, }:
pkgs.vimUtils.buildVimPlugin rec {
  inherit (source) pname version src;

  meta = with lib; {
    description = "Material colorscheme for NeoVim written in Lua with built-in support for native LSP, TreeSitter and many more plugins.";
    homepage = "https://github.com/marko-cerovac/material.nvim";
    license = licenses.gpl2;
  };
}