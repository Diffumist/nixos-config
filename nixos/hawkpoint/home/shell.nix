_: {
  programs = {
    fd.enable = true;
    fzf.enable = true;
    ripgrep.enable = true;
    zoxide.enable = true;
    jq.enable = true;
    nix-index-database.comma.enable = true;
    eza = {
      enable = true;
      git = true;
    };
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
        style = "changes,header";
      };
    };
    yazi = {
      enable = true;
      shellWrapperName = "yy";
    };
    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
    };
    fish = {
      enable = true;
      shellInit = ''
        set -g fish_greeting
      '';
    };
    starship = {
      enable = true;
      settings = {
        battery.disabled = true;
        directory = {
          read_only_style = "green";
          truncation_length = 3;
          truncation_symbol = "…/";
        };
      };
    };
    ghostty = {
      enable = true;
      settings = {
        theme = "dankcolors";
        font-family = "FiraCode Nerd Font Mono";
      };
    };
    direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
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
    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "noctalia";
        editor = {
          line-number = "relative";
          trim-final-newlines = true;
        };
      };
      themes = { };
    };
  };
}
