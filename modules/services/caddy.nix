{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.caddy;
  updateCloudflareTrustedProxies = pkgs.writeShellScript "update-cloudflare-trusted-proxies" ''
    set -euo pipefail

    target_dir=/var/lib/caddy
    target=$target_dir/cloudflare-trusted-proxies.caddy
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    ${pkgs.coreutils}/bin/install -o caddy -g caddy -m 0700 -d "$target_dir"
    if [ ! -e "$target" ]; then
      ${pkgs.coreutils}/bin/install -o caddy -g caddy -m 0644 /dev/null "$target"
    fi

    json="$tmpdir/cloudflare-ips.json"
    new="$tmpdir/cloudflare-trusted-proxies.caddy"

    if ! ${pkgs.curl}/bin/curl -fsSL \
      https://api.cloudflare.com/client/v4/ips \
      -o "$json"; then
      echo "failed to fetch Cloudflare IP ranges; keeping existing trusted proxy config"
      exit 0
    fi

    if ! ranges="$(
      ${pkgs.jq}/bin/jq -er '
        .result.ipv4_cidrs + .result.ipv6_cidrs | join(" ")
      ' "$json"
    )"; then
      echo "failed to parse Cloudflare IP ranges; keeping existing trusted proxy config"
      exit 0
    fi

    cat > "$new" <<EOF
    trusted_proxies static $ranges
    trusted_proxies_strict
    client_ip_headers CF-Connecting-IP X-Forwarded-For
    EOF

    if ! ${pkgs.diffutils}/bin/cmp -s "$new" "$target"; then
      ${pkgs.coreutils}/bin/install -o caddy -g caddy -m 0644 "$new" "$target"
      if ${pkgs.systemd}/bin/systemctl -q is-active caddy.service; then
        ${pkgs.systemd}/bin/systemctl reload caddy.service
      fi
    fi
  '';
in
{
  options = {
    my.services.caddy.enable = lib.mkEnableOption "The Caddy Service";
  };
  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "services@diffumist.me";
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy-cloudflare;
      globalConfig = ''
        acme_dns cloudflare {env.CF_API_TOKEN}
        servers {
          import /var/lib/caddy/cloudflare-trusted-proxies.caddy
        }
      '';
    };

    systemd.services.caddy = {
      requires = [ "caddy-cloudflare-trusted-proxies.service" ];
      after = [ "caddy-cloudflare-trusted-proxies.service" ];
      serviceConfig.EnvironmentFile = config.sops.templates."caddy-cloudflare.env".path;
    };
    sops.secrets.cloudflare_api_token = { };
    sops.templates."caddy-cloudflare.env" = {
      owner = "caddy";
      group = "caddy";
      mode = "0400";
      content = ''
        CF_API_TOKEN=${config.sops.placeholder.cloudflare_api_token}
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/caddy 0700 caddy caddy -"
      "f /var/lib/caddy/cloudflare-trusted-proxies.caddy 0644 caddy caddy -"
    ];

    systemd.services.caddy-cloudflare-trusted-proxies = {
      description = "Update Cloudflare trusted proxies for Caddy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      before = [ "caddy.service" ];
      wantedBy = [ "caddy.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        ${updateCloudflareTrustedProxies}
      '';
    };

    systemd.timers.caddy-cloudflare-trusted-proxies = {
      description = "Refresh Cloudflare trusted proxies for Caddy";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "12h";
        RandomizedDelaySec = "30m";
        Unit = "caddy-cloudflare-trusted-proxies.service";
      };
    };
    users.users.caddy.extraGroups = [ "acme" ];

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
    };
  };
}
