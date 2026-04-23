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

    target=/var/lib/caddy/cloudflare-trusted-proxies.caddy
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    json="$tmpdir/cloudflare-ips.json"
    new="$tmpdir/cloudflare-trusted-proxies.caddy"

    ${pkgs.curl}/bin/curl -fsSL \
      https://api.cloudflare.com/client/v4/ips \
      -o "$json"

    ranges="$(
      ${pkgs.jq}/bin/jq -er '
        .result.ipv4_cidrs + .result.ipv6_cidrs | join(" ")
      ' "$json"
    )"

    cat > "$new" <<EOF
    trusted_proxies static $ranges
    trusted_proxies_strict
    client_ip_headers CF-Connecting-IP X-Forwarded-For
    EOF

    if ! ${pkgs.diffutils}/bin/cmp -s "$new" "$target"; then
      ${pkgs.coreutils}/bin/install -o caddy -g caddy -m 0644 "$new" "$target"
      ${pkgs.systemd}/bin/systemctl reload caddy.service
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
      globalConfig = ''
        servers {
          import /var/lib/caddy/cloudflare-trusted-proxies.caddy
        }
      '';
    };
    systemd.tmpfiles.rules = [
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
