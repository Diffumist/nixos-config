{ lib, pkgs, ... }:

{
  # Ref: https://github.com/oxalica/nixos-config
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    userSettings = import ./settings.nix { inherit pkgs; };

    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
      ms-vscode.cpptools
      esbenp.prettier-vscode
      pkief.material-icon-theme
      eamodio.gitlens
      dbaeumer.vscode-eslint
      tamasfe.even-better-toml
      redhat.vscode-yaml
      jnoortheen.nix-ide
      github.copilot
    ] ++ import ./market-extensions.nix {
      inherit (pkgs.vscode-utils) extensionFromVscodeMarketplace;
    };
  };
}
