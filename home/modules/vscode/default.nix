{ lib, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    userSettings = import ./settings.nix { inherit pkgs; };

    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
      ms-python.python
      ms-vscode.cpptools
      vadimcn.vscode-lldb
      wakatime.vscode-wakatime
      esbenp.prettier-vscode
      pkief.material-icon-theme
      eamodio.gitlens
      dbaeumer.vscode-eslint
      formulahendry.code-runner
      tamasfe.even-better-toml
    ] ++ import ./market-extensions.nix {
      inherit (pkgs.vscode-utils) extensionFromVscodeMarketplace;
    };
  };
}
