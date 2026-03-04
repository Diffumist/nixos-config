{ config, pkgs, ... }:
{
  sops.secrets.cloudflare_acme_env = {
    sopsFile = ../secrets.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.webdav_env = {
    sopsFile = ../secrets.yaml;
    owner = "sftpgo";
    group = "sftpgo";
    mode = "0400";
  };

  sops.secrets.sftpgo_env = {
    sopsFile = ../secrets.yaml;
    owner = "sftpgo";
    group = "sftpgo";
    mode = "0400";
  };

  services.caddy = {
    enable = true;
    enableReload = true;
    email = "me@diffumist.me";
    openFirewall = true;

    virtualHosts."rqbit.diffumist.me" = {
      useACMEHost = "diffumist.me";
      extraConfig = ''
        encode gzip zstd
        reverse_proxy 127.0.0.1:3030
      '';
    };

    virtualHosts."sftpgo.diffumist.me" = {
      useACMEHost = "diffumist.me";
      extraConfig = ''
        encode gzip zstd

        handle_path /webdav* {
          reverse_proxy 127.0.0.1:6065
        }

        handle {
          reverse_proxy 127.0.0.1:8080
        }
      '';
    };
  };

  security.acme = {
    defaults.email = "me@diffumist.me";
    acceptTerms = true;
    certs."diffumist.me" = {
      credentialsFile = config.sops.secrets.cloudflare_acme_env.path;
      dnsProvider = "cloudflare";
      extraDomainNames = [ "*.diffumist.me" ];
    };
  };

  users.users.caddy.extraGroups = [ "acme" ];

  services.sftpgo = {
    enable = true;
    extraReadWriteDirs = [ "/persist/var/storage" ];

    loadDataFile = pkgs.writeText "sftpgo-users.json" (
      builtins.toJSON {
        users = [
          {
            username = "%env:SFTPGO_WEBDAV_USERNAME%";
            password = "%env:SFTPGO_WEBDAV_PASSWORD%";
            status = 1;
            home_dir = "/persist/var/storage";
            permissions = {
              "/" = [ "*" ];
            };
            filesystem = {
              provider = 0;
            };
          }
        ];
      }
    );

    settings = {
      common = {
        idle_timeout = 15;
        upload_mode = 0;
      };

      data_provider = {
        driver = "sqlite";
        name = "sftpgo.db";
        create_default_admin = true;
      };

      httpd.bindings = [
        {
          address = "127.0.0.1";
          port = 8080;
          enable_web_admin = true;
          enable_web_client = true;
        }
      ];

      sftpd.bindings = [
        {
          port = 0; # Disable SFTP
        }
      ];

      ftpd.bindings = [
        {
          port = 0; # Disable FTP
        }
      ];

      webdavd.bindings = [
        {
          address = "127.0.0.1";
          port = 6065;
        }
      ];
    };
  };

  systemd.services.sftpgo.serviceConfig.EnvironmentFile = [
    config.sops.secrets.sftpgo_env.path
    config.sops.secrets.webdav_env.path
  ];

  # 确保存储目录存在
  systemd.tmpfiles.rules = [
    "d /persist/var/storage 0755 sftpgo sftpgo -"
  ];
}