{ lib, pkgs, config, ... }:

{
  # Ref: https://github.com/oxalica/nixos-config
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    userSettings = import ./settings.nix { inherit config; };

    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
      esbenp.prettier-vscode
      pkief.material-icon-theme
      eamodio.gitlens
      dbaeumer.vscode-eslint
      tamasfe.even-better-toml
      redhat.vscode-yaml
      jnoortheen.nix-ide
      github.copilot
      ms-ceintl.vscode-language-pack-zh-hans
    ] ++ import ./market-extensions.nix {
      inherit (pkgs.vscode-utils) extensionFromVscodeMarketplace;
    };
  };
}
