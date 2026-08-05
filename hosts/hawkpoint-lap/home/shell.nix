{ pkgs, ... }:
{
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
    gh = {
      enable = true;
      extensions = [ pkgs.gh-eco ];
    };
    yazi = {
      enable = true;
      shellWrapperName = "yy";
    };
    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
    };
    bash = {
      enable = true;
      initExtra = ''
        enable -f ${pkgs.flyline}/lib/bash/libflyline.so flyline
      '';
    };
    fish = {
      enable = true;
      shellInit = ''
        set -g fish_greeting
        complete -c sops-flake -f -a '(__sops_flake_hosts)'
      '';
      functions = {
        __sops_flake_hosts = ''
          for secret in hosts/*/secrets.yaml
              string replace -r '^hosts/([^/]+)/secrets\.yaml$' '$1' "$secret"
          end
        '';
        sops-flake = ''
          set -l args
          set -l i 1

          while test $i -le (count $argv)
              set -l arg $argv[$i]

              if test "$arg" = hawkpoint-lap; and test (math $i + 1) -le (count $argv)
                  set -l next $argv[(math $i + 1)]

                  if test "$next" = sshosts
                      set args $args "hosts/hawkpoint-lap/home/sshosts.keytab"
                      set i (math $i + 2)
                      continue
                  end
              end

              if test -d "hosts/$arg"; and test (math $i + 1) -le (count $argv)
                  set -l service $argv[(math $i + 1)]
                  set -l found ""

                  for ext in json yaml yml
                      set -l service_file "hosts/$arg/services/$service.$ext"

                      if test -f "$service_file"
                          set found "$service_file"
                          break
                      end
                  end

                  if test -n "$found"
                      set args $args "$found"
                      set i (math $i + 2)
                      continue
                  end
              end

              set -l host_file "hosts/$arg/secrets.yaml"

              if test -f "$host_file"
                  set args $args "$host_file"
                  set i (math $i + 1)
                  continue
              end

              set args $args "$arg"
              set i (math $i + 1)
          end

          echo "[sops wrapper] command sops $args" >&2
          command sops $args
        '';
        realip = {
          body = ''
            if test -z "$argv[1]"
                echo "用法: realip <域名>"
                return 1
            end
            curl -s "https://dns.google/resolve?name=$argv[1]" | jq -r '.Answer[].data'
          '';
        };
      };
    };
    starship = {
      enable = true;
      settings = {
        battery.disabled = true;
        gcloud.disabled = true;
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
        font-family = "Maple Mono NF CN";
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
