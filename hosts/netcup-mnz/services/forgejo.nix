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
  runnerStateDirectory = "/var/lib/forgejo-runner";
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

  systemd.services.forgejo-runner = {
    description = "Forgejo Actions runner";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "podman.service"
    ];
    environment = {
      DOCKER_HOST = "unix:///run/podman/podman.sock";
      HOME = runnerStateDirectory;
    };
    path = [ pkgs.coreutils ];
    serviceConfig = {
      DynamicUser = true;
      User = "forgejo-runner";
      StateDirectory = "forgejo-runner";
      WorkingDirectory = runnerStateDirectory;
      ExecStart = "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config ${runnerConfig}";
      LoadCredential = [ "forgejo-token:${config.sops.secrets.forgejo_runner_token.path}" ];
      SupplementaryGroups = [ "podman" ];
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

  services.fail2ban.jails.forgejo = lib.mkIf config.services.fail2ban.enable {
    settings = {
      enabled = true;
      filter = "forgejo";
      backend = "systemd";
      journalmatch = "_SYSTEMD_UNIT=forgejo.service";
      port = "80,443";
      protocol = "tcp,udp";
      maxretry = 5;
      bantime = "24h";
    };
  };

  environment.etc."fail2ban/filter.d/forgejo.local" = lib.mkIf config.services.fail2ban.enable {
    text = ''
      [Definition]
      failregex = ^.*Failed authentication attempt for .* from <HOST>.*$
                  ^.*invalid credentials from <HOST>.*$
    '';
  };

  my.networking.usedTCPPorts.forgejo-http = port;
}
