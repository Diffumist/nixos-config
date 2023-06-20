{ ... }:
{
  programs.fish = {
    enable = true;
    shellInit = ''
      export LANG="en_US.UTF-8"
      set -g fish_greeting
    '';
    shellAliases = {
      oath = "ykman -r Canokey oath accounts code";
    };
  };
  # utils
  programs.starship = {
    enable = true;
    settings = {
      directory = {
        read_only_style = "green";
        truncation_length = 3;
        truncation_symbol = "…/";
      };
    };
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Ref: https://github.com/nix-community/nix-direnv#storing-direnv-outside-the-project-directory
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
  programs = {
    zoxide.enable = true;
    fzf = {
      enable = true;
      defaultCommand = "rg --files --hidden";
      defaultOptions = [ "--preview 'bat --color=always --style=plain --line-range=:500 {}'" ];
    };
    nix-index.enable = true;
    exa = {
      enable = true;
      enableAliases = true;
    };
    bat = {
      enable = true;
      config = {
        theme = "ansi";
        pager = "less -FR";
        style = "plain";
      };
    };
  };
}
