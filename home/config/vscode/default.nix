{ lib, pkgs, ... }:

{
  # Ref: https://github.com/oxalica/nixos-config
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    userSettings = import ./settings.nix { inherit pkgs; };

    extensions = with pkgs.vscode-extensions; [
      # matklad.rust-analyzer # waiting https://github.com/NixOS/nixpkgs/pull/142851
      ms-vscode.cpptools
      esbenp.prettier-vscode
      pkief.material-icon-theme
      eamodio.gitlens
      dbaeumer.vscode-eslint
      tamasfe.even-better-toml
      redhat.vscode-yaml
      jnoortheen.nix-ide
    ] ++ import ./market-extensions.nix {
      inherit (pkgs.vscode-utils) extensionFromVscodeMarketplace;
    };
  };
}
