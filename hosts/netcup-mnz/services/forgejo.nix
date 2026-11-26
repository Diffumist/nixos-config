{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "git.418.cat";
  port = 3000;
  runnerService = "forgejo-runner.service";
  runnerUid = 950;
  runnerHome = "/var/lib/forgejo-runner-rootless";
  runnerPodmanSocket = "/run/user/${toString runnerUid}/podman/podman.sock";
  runnerConfig = (pkgs.formats.yaml { }).generate "forgejo-runner.yaml" {
    log.level = "info";
    runner = {
      capacity = 1;
      labels = [
        "node:docker://docker.io/library/node:24-bookworm"
        "nix:docker://docker.io/nixos/nix:2.34.8"
      ];
      timeout = "3h";
      shutdown_timeout = "3h";
    };
    cache.enabled = false;
    container = {
      docker_host = "-";
      force_pull = true;
      privileged = false;
      valid_volumes = [ ];
    };
    server.connections.forgejo = {
      url = "https://${domain}/";
      uuid = "83fb58aa-b5ba-406d-87ac-516d5b43374a";
      token_url = "file:$CREDENTIALS_DIRECTORY/forgejo-token";
    };
  };
in
{
  sops.secrets.forgejo_runner_token = {
    sopsFile = ./forgejo.yaml;
    restartUnits = [ runnerService ];
  };

  my.services.postgresql.enable = true;

  # Persistent repositories must retain their owner when the ephemeral root is recreated.
  users.users.forgejo.uid = 998;
  users.groups.forgejo.gid = 997;

  # Dedicated unprivileged user for rootless Podman so forgejo-runner never touches host rootful podman.sock.
  users.groups.forgejo-runner.gid = runnerUid;
  users.users.forgejo-runner = {
    uid = runnerUid;
    isSystemUser = true;
    group = "forgejo-runner";
    home = runnerHome;
    createHome = true;
    linger = true;
    autoSubUidGidRange = true;
  };

  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = port;
        PROTOCOL = "http";
        SSH_DOMAIN = domain;
        SSH_PORT = 22;
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
    };
  };

  environment.systemPackages = [ config.services.forgejo.package ];

  my.systemd.harden = [
    "forgejo"
    "forgejo-runner"
  ];

  # Work around crun 1.31 failing rootless exec when lowering oom_score_adj
  # from user@.service's default 100 to 0 (containers/crun#2467).
  systemd.services."user@${toString runnerUid}" = {
    overrideStrategy = "asDropin";
    serviceConfig.OOMScoreAdjust = 0;
  };

  systemd.services.forgejo-runner = {
    description = "Forgejo Actions runner";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "network-online.target"
      "linger-users.service"
      "user@${toString runnerUid}.service"
    ];
    after = [
      "network-online.target"
      "linger-users.service"
      "user@${toString runnerUid}.service"
    ];
    environment = {
      DOCKER_HOST = "unix://${runnerPodmanSocket}";
      HOME = runnerHome;
    };
    path = [ pkgs.coreutils ];
    serviceConfig = {
      User = "forgejo-runner";
      Group = "forgejo-runner";
      WorkingDirectory = runnerHome;
      ReadWritePaths = [ runnerHome ];
      # ProtectHome=true hides /run/user, which blocks access to the rootless Podman user socket.
      ProtectHome = false;
      InaccessiblePaths = [
        "/home"
        "/root"
      ];
      ExecStart = "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config ${runnerConfig}";
      LoadCredential = [ "forgejo-token:${config.sops.secrets.forgejo_runner_token.path}" ];
      Restart = "on-failure";
      RestartSec = "2s";
      UMask = "0077";
    };
  };

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain}.useCloudflareACME = true;
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy 127.0.0.1:${toString port}
  '';

  my.services.reaction.webRules.forgejo = {
    unit = "forgejo.service";
    regex = [
      "Failed authentication attempt for .* from <ip>"
      "invalid credentials from <ip>"
    ];
    retry = 5;
  };

  my.networking.usedTCPPorts.forgejo-http = port;
}
