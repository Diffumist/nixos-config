{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.mihomo-server;
  acmeService = "acme-${cfg.domain}.service";
  certificateDirectory = "/var/lib/acme/${cfg.domain}";
  certificateGroup = "mihomo-server";
  serverConfig = {
    ipv6 = true;
    "log-level" = "info";
    mode = "direct";
    listeners = [
      {
        name = "anytls-tcp-in";
        type = "anytls";
        listen = "::";
        port = cfg.port;
        users.default = config.sops.placeholder.singbox_passwd;
        certificate = "${certificateDirectory}/fullchain.pem";
        "private-key" = "${certificateDirectory}/key.pem";
        alpn = [
          "h2"
          "http/1.1"
        ];
      }
      {
        name = "hysteria-udp-in";
        type = "hysteria2";
        listen = "::";
        port = cfg.port;
        users.default = config.sops.placeholder.singbox_passwd;
        "ignore-client-bandwidth" = true;
        masquerade = "https://macguy.io";
        certificate = "${certificateDirectory}/fullchain.pem";
        "private-key" = "${certificateDirectory}/key.pem";
        alpn = [ "h3" ];
      }
    ];
  };
in
{
  options.my.services.mihomo-server = {
    enable = lib.mkEnableOption "the shared Mihomo proxy server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain used for ACME certificate issuance.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = "Shared TCP and UDP listen port.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.my.services.sing-box.enable;
        message = "my.services.mihomo-server conflicts with my.services.sing-box.";
      }
    ];

    sops.secrets = {
      singbox_passwd = {
        sopsFile = ../../profiles/common/secrets/server.yaml;
        restartUnits = [ "mihomo.service" ];
      };
      cloudflare_api_token.sopsFile = ../../profiles/common/secrets/server.yaml;
    };

    sops.templates."mihomo-server.yaml" = {
      mode = "0400";
      content = builtins.toJSON serverConfig;
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "services@diffumist.me";
      certs.${cfg.domain} = {
        dnsProvider = "cloudflare";
        credentialFiles = {
          CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
          CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
        };
        group = certificateGroup;
        reloadServices = [ "mihomo.service" ];
      };
    };

    users.groups.${certificateGroup} = { };

    services.mihomo = {
      enable = true;
      configFile = config.sops.templates."mihomo-server.yaml".path;
      tunMode = false;
      processesInfo = false;
    };

    systemd.services.mihomo = {
      wants = [ acmeService ];
      after = [ acmeService ];
      environment.SAFE_PATHS = certificateDirectory;
      serviceConfig = {
        SupplementaryGroups = [ certificateGroup ];
        ExecStartPre = [
          "${lib.getExe config.services.mihomo.package} -t -d \${STATE_DIRECTORY} -f \${CREDENTIALS_DIRECTORY}/config.yaml"
        ];
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };

    my.networking = {
      usedTCPPorts.mihomo = cfg.port;
      usedUDPPorts.mihomo = cfg.port;
    };
  };
}
