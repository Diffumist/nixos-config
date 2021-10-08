{ ... }:
{
  programs.fish = {
    enable = true;
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
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      pager = "less -FR";
      style = "";
    };
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    nix-direnv.enableFlakes = true;
    enableFishIntegration = true;
    stdlib = ''
      : ''${XDG_CACHE_HOME:=$HOME/.cache}
      declare -A direnv_layout_dirs
      direnv_layout_dir() {
        echo "''${direnv_layout_dirs[$PWD]:=$(
          echo -n "$XDG_CACHE_HOME"/direnv/layouts/
          echo -n "$PWD" | sha1sum | cut -d ' ' -f 1
        )}"
      }
    '';
  };
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
}
