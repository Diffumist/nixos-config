{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.system.anti-lockout;

  targetType = lib.types.submodule {
    options = {
      host = lib.mkOption {
        type = lib.types.str;
        description = "Public host or IP address to probe.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        description = "TCP port to probe.";
      };
    };
  };

  targets = lib.concatMapStringsSep "\n" (
    target: "    ${lib.escapeShellArg "${target.host} ${toString target.port}"}"
  ) cfg.targets;

  boolString = value: if value then "1" else "0";

  checkScript = pkgs.writeShellScript "anti-lockout-check" ''
        set -euo pipefail

        state_dir="/var/lib/anti-lockout"
        healthy_system_file="$state_dir/healthy-system"
        rollback_lock_file="$state_dir/rollback-attempted"
        current_system="$(${pkgs.coreutils}/bin/readlink -f /run/current-system)"
        rollback_unknown_generation=${boolString cfg.rollbackUnknownGeneration}
        targets=(
    ${targets}
        )

        check_target() {
          local host="$1"
          local port="$2"

          ${pkgs.coreutils}/bin/timeout ${toString cfg.connectTimeoutSec}s \
            ${pkgs.bash}/bin/bash -c 'exec 3<>"/dev/tcp/$1/$2"' bash "$host" "$port"
        }

        check_public_network() {
          local target

          for target in "''${targets[@]}"; do
            set -- $target

            if check_target "$1" "$2"; then
              echo "public network probe succeeded via $1:$2"
              return 0
            fi
          done

          return 1
        }

        mark_healthy() {
          ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
          printf '%s\n' "$current_system" > "$healthy_system_file"
          ${pkgs.coreutils}/bin/rm -f "$rollback_lock_file"
        }

        rollback_and_reboot() {
          ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
          ${pkgs.coreutils}/bin/touch "$rollback_lock_file"
          ${config.system.build.nixos-rebuild}/bin/nixos-rebuild --no-reexec boot --rollback
          ${pkgs.systemd}/bin/systemctl reboot
        }

        ${pkgs.coreutils}/bin/sleep ${toString cfg.initialDelaySec}s

        attempt=1
        while [ "$attempt" -le ${toString cfg.attempts} ]; do
          if check_public_network; then
            mark_healthy
            exit 0
          fi

          if [ "$attempt" -lt ${toString cfg.attempts} ]; then
            ${pkgs.coreutils}/bin/sleep ${toString cfg.intervalSec}s
          fi

          attempt=$((attempt + 1))
        done

        if [ -s "$healthy_system_file" ] && [ "$(${pkgs.coreutils}/bin/cat "$healthy_system_file")" = "$current_system" ]; then
          echo "public network probe failed, but current generation was already marked healthy; not rolling back"
          exit 0
        fi

        if [ ! -s "$healthy_system_file" ] && [ "$rollback_unknown_generation" != "1" ]; then
          echo "public network probe failed, but no known healthy generation exists yet; not rolling back"
          exit 0
        fi

        if [ -e "$rollback_lock_file" ]; then
          echo "public network probe failed, but automatic rollback was already attempted; not rolling back again"
          exit 0
        fi

        echo "public network probe failed for an unverified generation; rolling back to previous NixOS generation"
        rollback_and_reboot
  '';
in
{
  options.my.system.anti-lockout = {
    enable = lib.mkEnableOption "automatic rollback when an unverified boot loses public network connectivity";

    targets = lib.mkOption {
      type = lib.types.nonEmptyListOf targetType;
      default = [
        {
          host = "1.1.1.1";
          port = 443;
        }
        {
          host = "1.0.0.1";
          port = 443;
        }
        {
          host = "8.8.8.8";
          port = 443;
        }
        {
          host = "223.5.5.5";
          port = 53;
        }
      ];
      description = "Public TCP targets used to decide whether the host still has outbound network connectivity.";
    };

    initialDelaySec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = "Seconds to wait before the first public network probe.";
    };

    attempts = lib.mkOption {
      type = lib.types.ints.positive;
      default = 6;
      description = "Number of public network probe rounds before rollback is considered.";
    };

    intervalSec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 15;
      description = "Seconds to wait between failed probe rounds.";
    };

    connectTimeoutSec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "TCP connect timeout for each public network probe target.";
    };

    rollbackUnknownGeneration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Rollback even when this module has not recorded a previously healthy generation.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.anti-lockout = {
      description = "Rollback unverified NixOS generation after public network lockout";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = checkScript;
        StateDirectory = "anti-lockout";
        StateDirectoryMode = "0700";
      };
    };
  };
}
