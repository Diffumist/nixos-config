{ lib, pkgs, config, secrets, ... }:

{
  # Ref: https://github.com/oxalica/nixos-config
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    userSettings = import ./settings.nix { inherit config secrets; };

    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
      esbenp.prettier-vscode
      pkief.material-icon-theme
      eamodio.gitlens
      jnoortheen.nix-ide
      ms-ceintl.vscode-language-pack-zh-hans
      piousdeer.adwaita-theme
    ] ++ import ./market-extensions.nix {
      inherit (pkgs.vscode-utils) extensionFromVscodeMarketplace;
    };
  };
}
