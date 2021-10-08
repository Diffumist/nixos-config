{ lib, pkgs, ... }:

{
  # Ref: https://github.com/oxalica/nixos-config
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    userSettings = import ./settings.nix { inherit pkgs; };

    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
      # ms-python.python
      ms-vscode.cpptools
      vadimcn.vscode-lldb
      haskell.haskell
      esbenp.prettier-vscode
      pkief.material-icon-theme
      eamodio.gitlens
      dbaeumer.vscode-eslint
      formulahendry.code-runner
      tamasfe.even-better-toml
      jnoortheen.nix-ide
    ] ++ import ./market-extensions.nix {
      inherit (pkgs.vscode-utils) extensionFromVscodeMarketplace;
    };
  };
}
