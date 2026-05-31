{ config, pkgs, ... }:
let
  domain = "nixos.bond";
  port = 8001;
  uploadPath = "/persist/var/storage/rustypaste";
  settingsFormat = pkgs.formats.toml { };
  settingsFile = settingsFormat.generate "rustypaste.toml" {
    config.refresh_rate = "1s";

    server = {
      address = "127.0.0.1:${toString port}";
      url = "https://${domain}";
      max_content_length = "128MB";
      max_upload_dir_size = "15GB";
      upload_path = uploadPath;
      timeout = "30s";
      expose_version = false;
      expose_list = false;
      handle_spaces = "replace";
    };

    landing_page = {
      text = ''
        Pastebin on ${domain}

        Files expire after 7 days by default.

        Total storage is capped at 15 GB.

        Upload a file:
          curl -F "file=@example.txt" https://${domain}

        Paste from stdin:
          echo "hello" | curl -F "file=@-" https://${domain}

        Custom expiry:
          curl -F "file=@example.txt" -H "expire:1h" https://${domain}

        Override filename:
          curl -F "file=@example.txt" -H "filename: note.txt" https://${domain}

        One-shot file:
          curl -F "oneshot=@secret.txt" https://${domain}

        Shorten a URL:
          curl -F "url=https://example.com" https://${domain}

        Shorten a one-shot URL:
          curl -F "oneshot_url=https://example.com" https://${domain}

        Upload from remote URL:
          curl -F "remote=https://example.com/file.png" https://${domain}

        Custom expiry must be 30 days or less.
      '';
      content_type = "text/plain; charset=utf-8";
    };

    paste = {
      random_url = {
        type = "petname";
        words = 2;
        separator = "-";
      };
      default_extension = "txt";
      default_expiry = "7d";
      duplicate_files = true;
      delete_expired_files = {
        enabled = true;
        interval = "1h";
      };
      mime_override = [
        {
          mime = "image/jpeg";
          regex = "^.*\\.jpg$";
        }
        {
          mime = "image/png";
          regex = "^.*\\.png$";
        }
        {
          mime = "image/svg+xml";
          regex = "^.*\\.svg$";
        }
        {
          mime = "video/webm";
          regex = "^.*\\.webm$";
        }
        {
          mime = "video/x-matroska";
          regex = "^.*\\.mkv$";
        }
        {
          mime = "application/octet-stream";
          regex = "^.*\\.bin$";
        }
        {
          mime = "text/plain";
          regex = "^.*\\.(log|txt|diff|sh|rs|toml)$";
        }
      ];
      mime_blacklist = [
        "application/x-dosexec"
        "application/java-archive"
        "application/java-vm"
        "audio/"
      ];
      text_mime_overrides = [
        "application/toml"
        "application/yaml"
        "application/x-yaml"
      ];
    };
  };
in
{
  users.groups.rustypaste = { };
  users.users.rustypaste = {
    isSystemUser = true;
    group = "rustypaste";
    home = uploadPath;
  };

  systemd.tmpfiles.rules = [
    "d ${uploadPath} 0750 rustypaste rustypaste -"
  ];

  systemd.services.rustypaste = {
    description = "rustypaste file upload service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      CONFIG = settingsFile;
      RUST_LOG = "info";
    };
    serviceConfig = {
      ExecStart = "${pkgs.rustypaste}/bin/rustypaste";
      User = "rustypaste";
      Group = "rustypaste";
      WorkingDirectory = uploadPath;
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ uploadPath ];
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      LockPersonality = true;
    };
  };

  my.services.caddy.enable = true;
  services.caddy.virtualHosts.${domain} = {
    useACMEHost = domain;
    extraConfig = ''
      encode zstd gzip
      @badExpire {
        header expire *
        not header_regexp expire ^\s*(?:(?:0|[1-9]|[1-9][0-9]{1,5}|1[0-9]{6}|2[0-4][0-9]{5}|25[0-8][0-9]{4}|259[01][0-9]{3}|2592000)\s*(?:seconds?|secs?|s)|(?:0|[1-9]|[1-9][0-9]{1,3}|[1-3][0-9]{4}|4[0-2][0-9]{3}|43[01][0-9]{2}|43200)\s*(?:minutes?|mins?|m)|(?:0|[1-9]|[1-9][0-9]|[1-6][0-9]{2}|7[01][0-9]|720)\s*(?:hours?|hrs?|h)|(?:0|[1-9]|[12][0-9]|30)\s*(?:days?|d)|(?:0|[1-4])\s*(?:weeks?|w))\s*$
      }
      respond @badExpire "expire must be 30 days or less. Allowed units: s, min, h, d, w.\n" 400

      request_body {
        max_size 128MB
      }
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs.${domain} = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
