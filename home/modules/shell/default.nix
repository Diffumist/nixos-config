{ lib, pkgs, config, ... }:
{
  home.sessionVariables = {
    PATH = "$PATH\${PATH:+:}:$HOME/.local/bin";
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      docker = "podman";
    };
    shellInit = ''
      export LANG="en_US.UTF-8"
      set -g fish_greeting
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      battery = { disabled = true; };
      directory = {
        read_only_style = "green";
        truncation_length = 3;
        truncation_symbol = "…/";
      };
    };
  };
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  # home.packages =
  #   let
  #     nix-fish-completion = pkgs.runCommand "nix-fish-completion" { } ''
  #       install -Dm644 ${./completions/nix.fish} $out/share/fish/completions/nix.fish
  #     '';
  #   in
  #   [
  #     nix-fish-completion
  #   ];
}
