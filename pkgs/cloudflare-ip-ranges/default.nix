{
  caddy-cloudflare,
  coreutils,
  curl,
  diffutils,
  gitMinimal,
  jq,
  lib,
  stdenvNoCC,
  writeShellApplication,
  ...
}:

let
  metadata = builtins.fromJSON (builtins.readFile ./ips.json);
  updateScript = writeShellApplication {
    name = "update-cloudflare-ip-ranges";
    runtimeInputs = [
      coreutils
      curl
      diffutils
      gitMinimal
      jq
    ];
    text = ''
      repo_root="$(git rev-parse --show-toplevel)"
      target="$repo_root/pkgs/cloudflare-ip-ranges/ips.json"
      target_dir="$(dirname "$target")"
      candidate="$(mktemp "$target_dir/.ips.json.XXXXXX")"
      raw="$candidate.raw"
      trap 'rm -f "$candidate" "$raw"' EXIT

      curl --connect-timeout 10 --fail --location --max-time 30 \
        --retry 3 --retry-all-errors --silent --show-error \
        https://api.cloudflare.com/client/v4/ips \
        --output "$raw"

      jq -e '
        .success == true
        and (.result.ipv4_cidrs | length) > 0
        and (.result.ipv6_cidrs | length) > 0
        and (.result.etag | type == "string" and length > 0)
        and all(
          (.result.ipv4_cidrs + .result.ipv6_cidrs)[];
          type == "string" and length > 0
        )
      ' "$raw" >/dev/null
      jq . "$raw" > "$candidate"

      if cmp --silent "$candidate" "$target"; then
        echo "Cloudflare IP ranges are already up to date"
        exit 0
      fi

      chmod 0644 "$candidate"
      mv "$candidate" "$target"
      echo "Updated $target"
    '';
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cloudflare-ip-ranges";
  version = "etag-${builtins.substring 0 12 metadata.result.etag}";

  src = ./ips.json;

  nativeBuildInputs = [ jq ];
  nativeInstallCheckInputs = [ caddy-cloudflare ];

  dontUnpack = true;
  doInstallCheck = true;

  installPhase = ''
    runHook preInstall

    jq -e '
      .success == true
      and (.result.ipv4_cidrs | length) > 0
      and (.result.ipv6_cidrs | length) > 0
      and all(
        (.result.ipv4_cidrs + .result.ipv6_cidrs)[];
        type == "string" and length > 0
      )
    ' "$src" >/dev/null

    install -Dm644 "$src" "$out/share/cloudflare-ip-ranges/ips.json"
    jq -r '.result.ipv4_cidrs[]' "$src" \
      > "$out/share/cloudflare-ip-ranges/ipv4.txt"
    jq -r '.result.ipv6_cidrs[]' "$src" \
      > "$out/share/cloudflare-ip-ranges/ipv6.txt"

    ranges="$(
      jq -r '
        [.result.ipv4_cidrs[], .result.ipv6_cidrs[]]
        | join(" ")
      ' "$src"
    )"

    mkdir -p "$out/share/caddy"
    cat > "$out/share/caddy/cloudflare-trusted-proxies.caddy" <<EOF
    trusted_proxies static $ranges
    trusted_proxies_strict
    client_ip_headers CF-Connecting-IP X-Forwarded-For
    EOF

    cat > "$out/share/caddy/cloudflare-only.caddy" <<EOF
    @not_cloudflare_proxy not remote_ip $ranges
    abort @not_cloudflare_proxy
    EOF

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    cat > Caddyfile <<EOF
    {
      admin off
      auto_https off
      servers {
        import $out/share/caddy/cloudflare-trusted-proxies.caddy
      }
    }
    http://localhost {
      import $out/share/caddy/cloudflare-only.caddy
      respond 204
    }
    EOF

    caddy adapt --validate --adapter caddyfile --config Caddyfile >/dev/null

    runHook postInstallCheck
  '';

  passthru.updateScript = lib.getExe updateScript;
  passthru.nixUpdateUseUpdateScript = true;

  meta = {
    description = "Pinned Cloudflare IP ranges and generated Caddy configuration";
    homepage = "https://www.cloudflare.com/ips/";
    platforms = lib.platforms.all;
  };
})
