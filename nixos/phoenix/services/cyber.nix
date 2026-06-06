{
  config,
  lib,
  pkgs,
  ...
}:
let
  configPath = "/var/lib/cyber.yaml";
  imageName = "localhost/cybergroupmate-agent";
  imageTag = "latest";
  dockerfile = pkgs.writeText "cybergroupmate-agent.Dockerfile" ''
    FROM ghcr.io/archeb/cybergroupmate:agentic

    RUN apt-get update; \
      apt-get install -y --no-install-recommends \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libcups2 \
        libdrm2 \
        libgbm1 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        sudo; \
      rm -rf /var/lib/apt/lists/*

    RUN set -eux; \
      groupadd -g 10001 agent; \
      useradd -u 10001 -g 10001 -m -s /bin/bash agent; \
      mkdir -p /app/workspace /app/agent-data /home/agent/.claude; \
      chown -R agent:agent /app/workspace /app/agent-data /home/agent; \
      printf '%s\n' \
        'agent ALL=(root) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/bin/dpkg' \
        > /etc/sudoers.d/agent-apt; \
      chmod 0440 /etc/sudoers.d/agent-apt

    RUN printf '%s\n' \
      '#!/bin/sh' \
      'set -eu' \
      'mkdir -p /app/workspace /app/agent-data /home/agent/.claude' \
      '[ ! -e /app/config.yaml ] || chown agent:agent /app/config.yaml' \
      '[ ! -e /app/config.yaml ] || chmod 0600 /app/config.yaml' \
      'chown -R agent:agent /app/workspace /app/agent-data /home/agent' \
      'exec runuser -u agent -- "$@"' \
      > /usr/local/bin/cybergroupmate-entrypoint; \
      chmod 0755 /usr/local/bin/cybergroupmate-entrypoint

    ENV HOME=/home/agent
    ENTRYPOINT ["/usr/local/bin/cybergroupmate-entrypoint"]
    CMD ["npx", "tsx", "src/main.ts"]
  '';
in
{
  virtualisation.oci-containers.containers.cybergroupmate = {
    image = "${imageName}:${imageTag}";
    autoStart = true;
    pull = "never";
    ports = [
      "127.0.0.1:6767:6767"
      "127.0.0.1:9092:9092"
    ];
    volumes = [
      "${configPath}:/app/config.yaml"
      "cybergroupmate-workspace:/app/workspace"
      "cybergroupmate-agent-data:/app/agent-data"
    ];
    environment = {
      TZ = config.time.timeZone;
      HOME = "/home/agent";
      PATH = "/app/workspace/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
      XDG_CONFIG_HOME = "/app/workspace/.config";
      XDG_CACHE_HOME = "/app/workspace/.cache";
      XDG_DATA_HOME = "/app/workspace/.local/share";
      XDG_STATE_HOME = "/app/workspace/.local/state";
      PLAYWRIGHT_BROWSERS_PATH = "/app/workspace/.cache/ms-playwright";
    };
    extraOptions = [
      "--cap-drop=ALL"
      "--cap-add=CHOWN"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=FOWNER"
      "--cap-add=SETGID"
      "--cap-add=SETUID"
      "--tmpfs=/tmp:rw,nosuid,nodev,size=768m"
    ];
  };

  systemd.services.podman-cybergroupmate = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.AssertPathExists = configPath;
    environment.TMPDIR = "/var/lib/cybergroupmate-build-tmp";
    preStart = lib.mkBefore ''
      ${pkgs.coreutils}/bin/chown 10001:10001 ${configPath}
      ${pkgs.coreutils}/bin/chmod 0600 ${configPath}

      ${lib.getExe pkgs.podman} build \
        --pull=newer \
        --tag ${imageName}:${imageTag} \
        --file ${dockerfile} \
        /tmp
    '';
    serviceConfig = {
      StateDirectory = "cybergroupmate-build-tmp";
      StateDirectoryMode = "0700";
    };
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts."cyber.503418.xyz".extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:6767
  '';

  security.acme.certs."cyber.503418.xyz" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
