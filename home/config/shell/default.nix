{ pkgs, ... }:
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
  programs.tmux = {
    enable = true;
    mouse = true;
    clock24 = true;
    shell = "${pkgs.fish}/bin/fish";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = yank;
        extraConfig = "set -g @yank_with_mouse on";
      }
      {
        plugin = dracula;
        extraConfig = ''
          set-option -g status-position top
          set -s copy-command 'wl-copy'
          unbind-key MouseDown2Pane
          bind-key -n MouseDown2Pane run "wl-paste | tmux load-buffer -; tmux paste-buffer"
          set -g @dracula-plugins "ram-usage"
          set -g @dracula-refresh-rate 10
          set -g @dracula-show-battery false
          set -g @dracula-show-timezone false
          set -g @dracula-show-powerline true
          set -g @dracula-network-bandwidth-show-interface false
          set -g @dracula-show-timezone false
          set -g @dracula-git-disable-status false
        '';
      }
    ];
  };
}
