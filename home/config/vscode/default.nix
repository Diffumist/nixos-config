{ pkgs, config, secrets, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    userSettings = import ./settings.nix { inherit config secrets; };

    extensions = with pkgs.vscode-marketplace; [
      rust-lang.rust-analyzer
      esbenp.prettier-vscode
      pkief.material-icon-theme
      eamodio.gitlens
      jnoortheen.nix-ide
      ms-pyright.pyright
      golang.go
      ms-ceintl.vscode-language-pack-zh-hans
      nvarner.typst-lsp
      mkhl.direnv
      pkief.material-product-icons
    ];
  };
}
