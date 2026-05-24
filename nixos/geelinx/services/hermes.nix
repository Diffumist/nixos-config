{ config, pkgs, ... }:
{
  sops = {
    secrets."hermes-env" = {
      format = "yaml";
      sopsFile = ./hermes.yaml;
    };
  };
  services.hermes-agent = {
    enable = true;
    container = {
      enable = true;
      image = "debian:trixie";
      backend = "podman";
    };
    addToSystemPackages = true;
    extraPackages = with pkgs; [
      uv
      pandoc
      imagemagick
    ];
    environmentFiles = [
      config.sops.secrets."hermes-env".path
    ];
    settings = {
      terminal.backend = "local";
      toolsets = [ "all" ];
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      platforms.api_server = {
        enabled = true;
        extra = {
          host = "127.0.0.1";
          port = 8642;
        };
      };
    };
    mcpServers = {
      deepwiki = {
        url = "https://mcp.deepwiki.com/mcp";
      };
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
      };
      mcp-nixos = {
        command = "uvx";
        args = [
          "mcp-nixos"
        ];
      };
    };
  };
  my.services.caddy.enable = true;
  services.caddy.virtualHosts."hermes.diffumist.me".extraConfig = ''
    forward_auth https://auth.diffumist.me {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
    }
    encode zstd gzip
    reverse_proxy 127.0.0.1:8642
  '';
  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };
  security.acme.certs."hermes.diffumist.me" = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
