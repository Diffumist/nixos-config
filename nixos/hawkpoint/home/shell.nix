_: {
  programs = {
    fd.enable = true;
    fzf.enable = true;
    ripgrep.enable = true;
    zoxide.enable = true;
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
        theme = "noctalia";
      };
      themes = {
        noctalia = {
          background = "#131313";
          foreground = "#e2e2e2";
          cursor-color = "#e2e2e2";
          cursor-text = "#131313";
          selection-background = "#d3bfe6";
          selection-foreground = "#382a49";
          palette = [
            "0 = #474747"
            "1 = #ffb4ab"
            "2 = #97cbff"
            "3 = #b9c8da"
            "4 = #d3bfe6"
            "5 = #97cbff"
            "6 = #b9c8da"
            "7 = #e2e2e2"
            "8 = #c6c6c6"
            "9 = #ffb4ab"
            "10 = #97cbff"
            "11 = #b9c8da"
            "12 = #d3bfe6"
            "13 = #97cbff"
            "14 = #b9c8da"
            "15 = #e2e2e2"
          ];
        };
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
