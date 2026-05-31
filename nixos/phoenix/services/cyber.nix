{
  config,
  lib,
  pkgs,
  ...
}:
let
  configSecret = config.sops.secrets.cybergroupmate-config;
  stateDir = "/var/lib/cybergroupmate";

  imageName = "localhost/cybergroupmate-nixos";
  imageTag = "nix";

  containerPath = lib.makeBinPath (
    with pkgs;
    [
      cybergroupmate
      nix
      bashInteractive
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      gnutar
      gzip
      xz
      bzip2
      git
      curl
      cacert
    ]
  );

  entrypoint = pkgs.writeShellApplication {
    name = "cybergroupmate-container-entrypoint";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.cybergroupmate
    ];
    text = ''
      set -euo pipefail

      install -d -m 0700 ${stateDir}
      install -m 0400 /run/secrets/cybergroupmate-config.yaml ${stateDir}/config.yaml

      exec ${lib.getExe pkgs.cybergroupmate} "$@"
    '';
  };

  image = pkgs.dockerTools.buildLayeredImage {
    name = imageName;
    tag = imageTag;

    contents = with pkgs; [
      entrypoint
      cybergroupmate
      nix
      bashInteractive
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      gnutar
      gzip
      xz
      bzip2
      git
      curl
      cacert
      iana-etc
      dockerTools.fakeNss
    ];

    extraCommands = ''
      mkdir -p bin etc/nix tmp var/lib/cybergroupmate
      ln -sf ${lib.getExe pkgs.bashInteractive} bin/bash
      ln -sf ${lib.getExe pkgs.bashInteractive} bin/sh
      chmod 1777 tmp

      cat > etc/nix/nix.conf <<'EOF'
      experimental-features = nix-command flakes auto-allocate-uids
      accept-flake-config = true
      auto-allocate-uids = true
      sandbox = false
      build-users-group =
      EOF
    '';

    config = {
      Entrypoint = [ "${lib.getExe entrypoint}" ];
      WorkingDir = stateDir;
      Env = [
        "CYBERGROUPMATE_HOME=${stateDir}"
        "HOME=${stateDir}"
        "NODE_ENV=production"
        "LOG_LEVEL=info"
        "PATH=${containerPath}"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_PATH=nixpkgs=flake:nixpkgs"
        "SHELL=${lib.getExe pkgs.bashInteractive}"
      ];
      ExposedPorts = {
        "6767/tcp" = { };
        "9092/tcp" = { };
      };
    };
  };
in
{
  sops.secrets.cybergroupmate-config = {
    sopsFile = ./cyber.yaml;
    key = "";
    mode = "0400";
    restartUnits = [ "podman-cybergroupmate.service" ];
  };

  virtualisation.oci-containers.containers.cybergroupmate = {
    image = "${imageName}:${imageTag}";
    imageFile = image;
    autoStart = true;
    pull = "never";
    ports = [
      "127.0.0.1:6767:6767"
      "127.0.0.1:9092:9092"
    ];
    volumes = [
      "${configSecret.path}:/run/secrets/cybergroupmate-config.yaml:ro"
      "cybergroupmate-state:${stateDir}"
    ];
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--tmpfs=/tmp:rw,nosuid,nodev,size=512m"
    ];
  };

  systemd.services.podman-cybergroupmate = {
    after = [
      "sops-nix.service"
      "network-online.target"
    ];
    requires = [ "sops-nix.service" ];
    wants = [ "network-online.target" ];
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
