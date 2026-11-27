{
  pkgs,
  config,
  inputs,
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
        llm-agents.claude-code
        llm-agents.rtk
        nix
        ripgrep
        which
        config.programs.go.package
        config.programs.uv.package
      ]
      ++ sharedDevPackages;
  };

  jail = inputs.jail-nix.lib.extend {
    inherit pkgs;
    basePermissions =
      combinators: with combinators; [
        base
        fake-passwd
      ];
  };

  ccboxEntry = pkgs.writeShellApplication {
    name = "ccbox-entry";
    text = ''
      if [ "''${1:-}" = "--shell" ]; then
        shift
        if [ "$#" -eq 0 ]; then
          exec bash -i
        fi
        exec bash "$@"
      fi
      exec claude "$@"
    '';
  };

  ccbox = jail "ccbox" ccboxEntry (
    combinators: with combinators; [
      # Share host network namespace (egress handled by host mihomo tun) without exposing /etc/nix or host timezone.
      (share-ns "net")
      (set-hostname "workstation")
      (write-text "/etc/hostname" "workstation\n")
      (unsafe-add-raw-args "--hostname workstation")
      (try-readonly "/etc/hosts")
      (try-readonly "/etc/nsswitch.conf")
      (try-readonly "/etc/resolv.conf")
      (try-readonly "/etc/ssl")
      (try-readonly "/run/systemd/resolve")

      # Expose /nix/store, /usr/bin/env, timezone data, and host nix-ld for native claude / prebuilt binaries.
      (ro-bind "/nix/store" "/nix/store")
      (ro-bind "${pkgs.coreutils}/bin/env" "/usr/bin/env")
      (ro-bind "${pkgs.tzdata}/share/zoneinfo" "/usr/share/zoneinfo")
      (ro-bind "${pkgs.tzdata}/share/zoneinfo/America/Los_Angeles" "/etc/localtime")
      (try-ro-bind "/lib64/ld-linux-x86-64.so.2" "/lib64/ld-linux-x86-64.so.2")
      (try-readonly "/run/current-system/sw/share/nix-ld")
      (try-fwd-env "NIX_LD")
      (try-fwd-env "NIX_LD_LIBRARY_PATH")

      # Clean environment with US locale/timezone and disabled Claude telemetry.
      (fwd-env "USER")
      (set-env "SHELL" "${pkgs.bashInteractive}/bin/bash")
      (set-env "TERM" (noescape ''"''${TERM:-xterm-256color}"''))
      (set-env "COLORTERM" "truecolor")
      (set-env "TZ" "America/Los_Angeles")
      (set-env "TZDIR" "${pkgs.tzdata}/share/zoneinfo")
      (set-env "LANG" "en_US.UTF-8")
      (set-env "LC_ALL" "en_US.UTF-8")
      (set-env "LANGUAGE" "en_US:en")
      (set-env "LOCALE_ARCHIVE" "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive")
      (set-env "SSL_CERT_FILE" "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt")
      (set-env "DISABLE_AUTOUPDATER" "1")
      (set-env "DISABLE_TELEMETRY" "1")
      (set-env "DISABLE_ERROR_REPORTING" "1")

      (add-runtime ''
        box_home="''${CCBOX_HOME:-''${XDG_DATA_HOME:-$HOME/.local/share}/ccbox/home}"
        projects_dir="$HOME/Projects"

        mkdir -p \
          "$box_home/.agents/skills" \
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

        # Sync shared hooks/plugins/UI prefs while keeping sandbox auth, model, and env isolated from host magpie config.
        host_settings="$HOME/.claude/settings.json"
        box_settings="$box_home/.claude/settings.json"
        if [ -f "$host_settings" ]; then
          [ -f "$box_settings" ] || printf '{}\n' > "$box_settings"
          tmp_settings="$(mktemp "$box_home/.claude/settings.json.XXXXXX")"
          ${pkgs.jq}/bin/jq -s '
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

        # Bind persistent sandbox home first so subsequent subpath binds layer on top of it.
        RUNTIME_ARGS+=(--bind "$box_home" "$HOME")

        # Mount host projects at the same path so Claude project memory and AGENTS.md resolve identically.
        if [ -d "$projects_dir" ]; then
          RUNTIME_ARGS+=(--bind "$projects_dir" "$projects_dir")
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
            RUNTIME_ARGS+=(--bind "$PWD" "$PWD")
            ;;
        esac
        RUNTIME_ARGS+=(--chdir "$workdir")

        # Share Claude Code binary and selected config/skill subtrees at identical host paths.
        for ro_path in \
          "$HOME/.agents/skills" \
          "$HOME/.local/share/claude" \
          "$HOME/.local/bin/claude" \
          "$HOME/.claude/CLAUDE.md" \
          "$HOME/.claude/RTK.md" \
          "$HOME/.claude/skills" \
          "$HOME/.claude/hooks"; do
          if [ -e "$ro_path" ]; then
            RUNTIME_ARGS+=(--ro-bind "$ro_path" "$ro_path")
          fi
        done

        # Plugins write sweep/catalog caches inside ~/.claude/plugins, so mount rw.
        if [ -d "$HOME/.claude/plugins" ]; then
          RUNTIME_ARGS+=(--bind "$HOME/.claude/plugins" "$HOME/.claude/plugins")
        fi

        # Forward herdr hook socket only when launched inside a herdr pane.
        if [ "''${HERDR_ENV:-}" = "1" ] && [ -S "''${HERDR_SOCKET_PATH:-}" ] && [ -n "''${HERDR_PANE_ID:-}" ]; then
          RUNTIME_ARGS+=(
            --setenv HERDR_ENV 1
            --setenv HERDR_PANE_ID "$HERDR_PANE_ID"
            --setenv HERDR_SOCKET_PATH "$HERDR_SOCKET_PATH"
            --bind "$HERDR_SOCKET_PATH" "$HERDR_SOCKET_PATH"
          )
        fi

        # Allow nix eval/build via host nix-daemon without mounting host /etc/nix (avoids CN mirrors & tokens).
        if [ -d /nix/var/nix/daemon-socket ]; then
          RUNTIME_ARGS+=(
            --bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket
            --setenv NIX_REMOTE daemon
            --setenv NIX_CONFIG $'experimental-features = nix-command flakes\nwarn-dirty = false\nuse-xdg-base-directories = true'
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
              RUNTIME_ARGS+=(--setenv "$var" "''${!var}")
            fi
          done
        fi

        box_path="$HOME/.local/bin''${devshell_path:+:$devshell_path}:${ccboxEnv}/bin:/bin"
        RUNTIME_ARGS+=(--setenv PATH "$box_path")
      '')
    ]
  );
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
