{ ... }:
{
  programs.alacritty = {
    enable = true;
    # See: https://github.com/alacritty/alacritty/blob/master/alacritty.yml
    settings = {
      window = {
        dimensions = {
          columns = 110;
          lines = 35;
        };
        position = {
          x = 550;
          y = 550;
        };
        dynamic_title = true;
      };
      shell.program = "fish";
      mouse.hide_when_typing = true;
      font = {
        size = 10;
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
        bold = { family = "JetBrains Mono"; };
        italic = { family = "JetBrains Mono"; };
      };
      draw_bold_text_with_bright_colors = true;
      background_opacity = 1;
      colors = {
        primary = {
          background = "#272727";
          foreground = "#eff0eb";
        };
        selection = {
          text = "#282a36";
          background = "#feffff";
        };
        normal = {
          black = "#282a36";
          red = "#ff5c57";
          green = "#5af78e";
          yellow = "#f3f99d";
          blue = "#57c7ff";
          magenta = "#ff6ac1";
          cyan = "#9aedfe";
          white = "#f1f1f0";
        };
        bright = {
          black = "#686868";
          red = "#ff5c57";
          green = "#5af78e";
          yellow = "#f3f99d";
          blue = "#57c7ff";
          magenta = "#ff6ac1";
          cyan = "#9aedfe";
          white = "#eff0eb";
        };
      };
    };
  };
  programs.fish = {
    enable = true;
    shellInit = ''
      export LANG="en_US.UTF-8"
      set -g fish_greeting
    '';
    shellAliases = {
      nixfmt = "nixpkgs-fmt (fd -E pkgs -e nix)";
    };
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
