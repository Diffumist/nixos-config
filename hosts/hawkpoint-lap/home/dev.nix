{
  pkgs,
  config,
  osConfig,
  ...
}:
let
  # Shared CLI toolchains exposed both on the host and inside ccbox via read-only /nix/store.
  sharedDevPackages = with pkgs; [
    xh
    nixd
    nixfmt
    taplo
    yamlfmt
    yaml-language-server
    gdb
    gcc
    cmake
    gnumake
    ninja
    gopls
    typst
    oxfmt
    oxlint
    tsgolint
    typescript-language-server
    yarn-berry
    typescript
    nodejs
    pnpm
    rustc
    python3
    pyright
    patchelf
    hyperfine
    pkg-config
  ];

  # Base CLI tools + shared dev toolchains exposed inside ccbox via read-only /nix/store bind mount.
  ccboxEnv = pkgs.buildEnv {
    name = "ccbox-env";
    pathsToLink = [ "/bin" ];
    paths =
      with pkgs;
      [
        bashInteractive
        coreutils
        curl
        diffutils
        fd
        findutils
        gawk
        git
        gnugrep
        gnused
        jq
        less
        llm-agents.rtk
        nix
        ripgrep
        which
        config.programs.go.package
        config.programs.uv.package
      ]
      ++ sharedDevPackages;
  };

  ccbox = pkgs.writeShellApplication {
    name = "ccbox";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      podman
    ];
    text = ''
      # ponytail: rootless podman wrapper for CLI isolation; move to microvm only if GUI/Electron isolation is needed
      image="''${CCBOX_IMAGE:-docker.io/library/archlinux:latest}"
      proxy_port="''${CCBOX_PROXY_PORT:-7890}"
      box_home="''${CCBOX_HOME:-''${XDG_DATA_HOME:-$HOME/.local/share}/ccbox/home}"
      projects_dir="$HOME/Projects"

      shell_mode=0
      if [ "''${1:-}" = "--shell" ]; then
        shell_mode=1
        shift
      fi

      # Pre-create mountpoint parents as the host user so podman never creates root-mapped subdirs in box_home.
      mkdir -p \
        "$box_home/.claude/hooks" \
        "$box_home/.claude/plugins" \
        "$box_home/.claude/skills" \
        "$box_home/.local/bin" \
        "$box_home/.local/share/claude" \
        "$box_home/Projects"
      touch \
        "$box_home/.local/bin/claude" \
        "$box_home/.claude/CLAUDE.md" \
        "$box_home/.claude/RTK.md"

      # Sync shared hooks/plugins/UI prefs while keeping container auth, model, and env isolated from host magpie config.
      host_settings="$HOME/.claude/settings.json"
      box_settings="$box_home/.claude/settings.json"
      if [ -f "$host_settings" ]; then
        [ -f "$box_settings" ] || printf '{}\n' > "$box_settings"
        tmp_settings="$(mktemp "$box_home/.claude/settings.json.XXXXXX")"
        jq -s '
          .[0] as $box | .[1] as $host |
          $box + ($host | {
            hooks,
            enabledPlugins,
            extraKnownMarketplaces,
            statusLine,
            effortLevel,
            theme,
            skipDangerousModePermissionPrompt
          } | with_entries(select(.value != null)))
        ' "$box_settings" "$host_settings" > "$tmp_settings"
        mv "$tmp_settings" "$box_settings"
      fi

      # Loopback-only forwarding to host mihomo; no tap/default route acts as a hard kill switch.
      args=(
        --rm
        --userns=keep-id
        --passwd-entry="''${USER}:*:\$UID:\$GID::''${HOME}:/bin/bash"
        --network="pasta:--splice-only,-T,''${proxy_port},-t,none,-u,none,-U,none"
        --hostname=workstation
        --mount "type=bind,src=/nix/store,dst=/nix/store,ro"
        --mount "type=bind,src=${pkgs.tzdata}/share/zoneinfo/America/Los_Angeles,dst=/etc/localtime,ro"
        --mount "type=bind,src=${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive,dst=/usr/lib/locale/locale-archive,ro"
        --mount "type=bind,src=$box_home,dst=$HOME"
      )

      if [ -t 0 ] && [ -t 1 ]; then
        args+=(-it)
      else
        args+=(-i)
      fi

      # Mount host projects at the same path so Claude project memory and AGENTS.md resolve identically.
      if [ -d "$projects_dir" ]; then
        args+=(--mount "type=bind,src=$projects_dir,dst=$projects_dir")
      fi

      workdir="$PWD"
      case "$PWD" in
        "$projects_dir" | "$projects_dir"/*)
          ;;
        "$HOME" | "/")
          if [ -d "$projects_dir" ]; then
            workdir="$projects_dir"
          else
            workdir="$HOME"
          fi
          ;;
        *)
          args+=(--mount "type=bind,src=$PWD,dst=$PWD")
          ;;
      esac
      args+=(--workdir "$workdir")

      # Share Claude Code binary and selected config subtrees at identical host paths.
      for ro_path in \
        "$HOME/.local/share/claude" \
        "$HOME/.local/bin/claude" \
        "$HOME/.claude/CLAUDE.md" \
        "$HOME/.claude/RTK.md" \
        "$HOME/.claude/skills" \
        "$HOME/.claude/hooks"; do
        if [ -e "$ro_path" ]; then
          args+=(--mount "type=bind,src=$ro_path,dst=$ro_path,ro")
        fi
      done

      # Plugins write sweep/catalog caches inside ~/.claude/plugins, so mount rw.
      if [ -d "$HOME/.claude/plugins" ]; then
        args+=(--mount "type=bind,src=$HOME/.claude/plugins,dst=$HOME/.claude/plugins")
      fi

      # Forward herdr hook socket only when launched inside a herdr pane.
      if [ "''${HERDR_ENV:-}" = "1" ] && [ -S "''${HERDR_SOCKET_PATH:-}" ] && [ -n "''${HERDR_PANE_ID:-}" ]; then
        args+=(
          -e "HERDR_ENV=1"
          -e "HERDR_PANE_ID=$HERDR_PANE_ID"
          -e "HERDR_SOCKET_PATH=$HERDR_SOCKET_PATH"
          --mount "type=bind,src=$HERDR_SOCKET_PATH,dst=$HERDR_SOCKET_PATH"
        )
      fi

      # Allow nix eval/build via host nix-daemon without mounting host /etc/nix (avoids CN mirrors & tokens).
      if [ -d /nix/var/nix/daemon-socket ]; then
        args+=(
          --mount "type=bind,src=/nix/var/nix/daemon-socket,dst=/nix/var/nix/daemon-socket"
          -e "NIX_REMOTE=daemon"
          -e $'NIX_CONFIG=experimental-features = nix-command flakes\nwarn-dirty = false\nuse-xdg-base-directories = true'
        )
      fi

      # Inherit /nix/store toolchain entries when launched from a direnv/nix develop shell.
      devshell_path=""
      if [ -n "''${IN_NIX_SHELL:-}" ]; then
        IFS=':' read -r -a host_path_parts <<< "''${PATH:-}"
        for p in "''${host_path_parts[@]}"; do
          case "$p" in
            /nix/store/*)
              if [ -d "$p" ]; then
                devshell_path="''${devshell_path:+$devshell_path:}$p"
              fi
              ;;
          esac
        done
        for var in PKG_CONFIG_PATH NIX_CFLAGS_COMPILE NIX_LDFLAGS CMAKE_PREFIX_PATH; do
          if [ -n "''${!var:-}" ]; then
            args+=(-e "$var=''${!var}")
          fi
        done
      fi

      proxy_url="http://127.0.0.1:''${proxy_port}"
      box_path="$HOME/.local/bin''${devshell_path:+:$devshell_path}:${ccboxEnv}/bin:/usr/local/bin:/usr/bin:/bin"
      args+=(
        -e "HOME=$HOME"
        -e "USER=$USER"
        -e "TERM=''${TERM:-xterm-256color}"
        -e "COLORTERM=truecolor"
        -e "TZ=America/Los_Angeles"
        -e "LANG=en_US.UTF-8"
        -e "LC_ALL=en_US.UTF-8"
        -e "LANGUAGE=en_US:en"
        -e "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        -e "HTTP_PROXY=$proxy_url"
        -e "HTTPS_PROXY=$proxy_url"
        -e "ALL_PROXY=$proxy_url"
        -e "http_proxy=$proxy_url"
        -e "https_proxy=$proxy_url"
        -e "all_proxy=$proxy_url"
        -e "NO_PROXY=127.0.0.1,localhost"
        -e "no_proxy=127.0.0.1,localhost"
        -e "DISABLE_AUTOUPDATER=1"
        -e "DISABLE_TELEMETRY=1"
        -e "DISABLE_ERROR_REPORTING=1"
        -e "PATH=$box_path"
      )

      if [ "$shell_mode" -eq 1 ]; then
        if [ "$#" -eq 0 ]; then
          exec podman run "''${args[@]}" "$image" bash -i
        fi
        exec podman run "''${args[@]}" "$image" bash "$@"
      fi
      exec podman run "''${args[@]}" "$image" claude "$@"
    '';
  };
in
{
  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableExtraSocket = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };
  programs = {
    uv.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ osConfig.sops.secrets.sshosts.path ];
      extraOptionOverrides = {
        SetEnv = {
          TERM = "xterm-256color";
        };
        Compression = true;
        UpdateHostKeys = "yes";
        StrictHostKeyChecking = "no";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%h:%p";
        ControlPersist = "10m";
        HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519";
        KexAlgorithms = "mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com";
        MACs = "hmac-sha2-512-etm@openssh.com";
        Ciphers = "chacha20-poly1305@openssh.com";
      };
    };
    go = {
      enable = true;
      env = {
        GOPATH = "${config.xdg.cacheHome}/go";
        GOBIN = "${config.home.homeDirectory}/.local/bin";
      };
    };
    git = {
      enable = true;
      ignores = [
        ".vscode"
        ".DS_store"
        "docs/ai/"
      ];
      settings = {
        user.name = "Diffumist";
        user.email = "git@diffumist.me";
      };
      signing = {
        signByDefault = true;
        key = "8BA330B49A5694A6";
      };
    };
    jujutsu = {
      enable = true;
      settings = {
        user.name = "Diffumist";
        user.email = "git@diffumist.me";
        signing = {
          behavior = "own";
          key = "8BA330B49A5694A6";
        };
      };
    };
    lazygit.enable = true;
    jjui.enable = true;
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      settings.default-key = "8BA330B49A5694A6";
      scdaemonSettings.deny-admin = true;
    };
    vscodium = {
      enable = true;
      profiles.default.extensions = with pkgs.open-vsx-release; [
        golang.go
        mkhl.direnv
        docker.docker
        oxc.oxc-vscode
        jinxcappa.sopsie
        jnoortheen.nix-ide
        antfu.file-nesting
        oscarotero.vento-syntax
        thegeeklab.yamlfmt-ng
        tamasfe.even-better-toml
        rust-lang.rust-analyzer
        astro-build.astro-vscode
        piousdeer.adwaita-theme
        pkief.material-icon-theme
        pkief.material-product-icons
        ms-ceintl.vscode-language-pack-zh-hans
      ];
    };
    zed-editor = {
      enable = true;
      extensions = [ "nix" ];
    };
    distrobox = {
      enable = true;
      settings = {
        container_manager = "podman";
        container_image_default = "archlinux:latest";
        container_manager_additional_flags = ''
          --env=TZ=America/Los_Angeles
          --env=LANG=en_US.UTF-8
          --env=LC_ALL=en_US.UTF-8
          --env=LANGUAGE=en_US:en
        '';
      };
    };
  };
  home.packages =
    with pkgs;
    [
      ccbox
      age
      sops
      nix-init
      nixpkgs-review
      nix-output-monitor
    ]
    ++ sharedDevPackages;
}
