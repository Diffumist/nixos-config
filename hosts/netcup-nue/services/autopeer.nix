# Autopeer frontend: other networks log in with their registry credentials,
# get a peer on a node of ours and open a pull request against this repo.
# The agents on the nodes are modules/services/dn42/autopeer.nix.
{
  config,
  inputs,
  lib,
  ...
}:
let
  clearnetDomain = "peering.diffumist.me";
  dn42Domain = "peering.diffumist.dn42";
  port = 4800;
  registry = inputs.dn42-registry;
  ranet = config.my.services.ranet.nodes;
in
{
  sops.secrets = {
    autopeer_cookie_secret = { };
    autopeer_forgejo_token = { };
    autopeer_hook_token = { };
    autopeer_agent_token.sopsFile = ../../../profiles/common/secrets/server.yaml;
  };

  services.autopeer.web = {
    enable = true;
    settings = {
      listen = "127.0.0.1:${toString port}";
      asn = 4242420642;
      link_local = "fe80::642";
      # Kioubit login signs its answer for this name.
      domain = clearnetDomain;
      registry = "${registry}";
      registry_rev = registry.rev;
      registry_time = registry.lastModified;
      flapalerted = "https://flap-dn42.diffumist.me";
      forgejo = {
        url = "https://git.418.cat";
        repo = "DiftLab/nixos-config";
        dir = "profiles/common/services/peers";
      };
      nodes = lib.mapAttrsToList (
        name: node:
        let
          manual = !(node.autopeer or true);
          agentHost = if ranet ? ${node.hostName} then ranet.${node.hostName}.ipv6 else node.ipv6;
        in
        {
          inherit name manual;
          inherit (node)
            location
            provider
            capacity
            ;
          agent = "http://[${agentHost}]:4801";
        }
        // lib.optionalAttrs (!manual) {
          inherit (node) endpoint;
          public_key = node.publicKey;
        }
      ) (import ../../../profiles/common/services/dn42-nodes.nix);
    };
    secretFile = config.sops.secrets.autopeer_cookie_secret.path;
    agentTokenFile = config.sops.secrets.autopeer_agent_token.path;
    forgejoTokenFile = config.sops.secrets.autopeer_forgejo_token.path;
    hookTokenFile = config.sops.secrets.autopeer_hook_token.path;
  };

  my.systemd.harden = [ "autopeer-web" ];

  # Route .dn42 queries through DN42 anycast DNS so Caddy can reach acme.burble.dn42.
  services.resolved.enable = true;
  systemd.network.networks."10-dn42-dummy" = {
    dns = [
      "172.20.0.53"
      "fd42:d42:d42:54::1"
      "172.23.0.53"
      "fd42:d42:d42:53::1"
    ];
    domains = [ "~dn42" ];
    networkConfig = {
      DNSDefaultRoute = false;
      DNSSEC = false;
    };
  };

  my.services.caddy = {
    enable = true;
    virtualHosts = {
      ${clearnetDomain} = {
        useCloudflareOriginCert = true;
        cloudflareOnly = true;
      };
      ${dn42Domain} = { };
    };
  };
  services.caddy.virtualHosts = {
    ${clearnetDomain}.extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port}
    '';
    ${dn42Domain}.extraConfig = ''
      tls {
        issuer acme {
          dir https://acme.burble.dn42/v1/dn42/acme/directory
          email services@diffumist.me
        }
      }
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };

  my.networking.usedTCPPorts.autopeer = port;
}
